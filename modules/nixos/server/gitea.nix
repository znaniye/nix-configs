{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.gitea;
in

{

  config = lib.mkMerge [

    (lib.mkIf cfg.remoteRunner.enable {
      services.gitea-actions-runner.instances.${config.networking.hostName} = {
        enable = true;
        hostPackages = lib.mkOptionDefault [
          pkgs.nix
          pkgs.skopeo
        ];
        labels = [ "amd64:host" ];
        name = config.networking.hostName;
        tokenFile = "/run/gitea-remote-runner/token.env";
        url = "http://192.168.68.111:3000";
      };
      sops.secrets.gitea-pat-token = { };
      systemd.services.gitea-remote-runner-token = {
        after = [ "network-online.target" ];
        before = [ "gitea-runner-${config.networking.hostName}.service" ];
        description = "User-scoped registration token for the remote runner";
        path = with pkgs; [
          curl
          jq
          coreutils
        ];
        script = ''
          set -euo pipefail
          pat="$(cat ${config.sops.secrets.gitea-pat-token.path})"
          token="$(curl -s --fail -X POST -H "Authorization: token $pat" \
            http://192.168.68.111:3000/api/v1/user/actions/runners/registration-token \
            | jq -r .token)"
          install -d -m 0700 /run/gitea-remote-runner
          printf 'TOKEN=%s\n' "$token" > /run/gitea-remote-runner/token.env
          chmod 0400 /run/gitea-remote-runner/token.env
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
      };
      systemd.services."gitea-runner-${config.networking.hostName}" = {
        after = [ "gitea-remote-runner-token.service" ];
        requires = [ "gitea-remote-runner-token.service" ];
      };
    })

    (lib.mkIf cfg.enable {

      assertions = [
        {
          assertion = !(cfg.runner.enable && !cfg.runner.autoTokenFromSops && cfg.runner.tokenFile == null);
          message = "Set nixos.server.gitea.runner.tokenFile when nixos.server.gitea.runner.autoTokenFromSops is false and runner is enabled.";
        }
      ];
      networking.firewall.allowedTCPPorts = [
        3000
        2222
      ];
      services.gitea = {
        enable = true;
        settings = {
          actions.ENABLED = true;
          attachment = {
            ALLOWED_TYPES = "*/*";
            ENABLED = true;
          };
          "repository.upload" = {
            ALLOWED_TYPES = "*/*";
            ENABLED = true;
          };
          server = {
            SSH_PORT = 2222;
            START_SSH_SERVER = true;
          };
          service = {
            DISABLE_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
          };
        };
      };
      services.gitea-actions-runner.instances =
        lib.optionalAttrs cfg.runner.enable {
          local = {
            enable = true;
            hostPackages = lib.mkOptionDefault [
              pkgs.nix
            ];
            labels = cfg.runner.labels;
            name = cfg.runner.name;
            tokenFile =
              if cfg.runner.autoTokenFromSops then
                config.sops.templates.gitea-runner-env.path
              else
                cfg.runner.tokenFile;
            url = cfg.runner.url;
          };
        }
        // lib.optionalAttrs cfg.runner.shared.enable {
          shared = {
            enable = true;
            hostPackages = lib.mkOptionDefault [
              pkgs.nix
            ];
            labels = cfg.runner.labels;
            name = cfg.runner.shared.name;
            tokenFile = cfg.runner.shared.tokenEnvPath;
            url = cfg.runner.url;
          };
        };
      sops.secrets = lib.mkIf (cfg.runner.enable && cfg.runner.autoTokenFromSops) {
        ${cfg.runner.tokenSecretName} = {
          mode = "0400";
          owner = "root";
        };
      };
      sops.templates = lib.mkIf (cfg.runner.enable && cfg.runner.autoTokenFromSops) {
        gitea-runner-env = {
          content = ''
            TOKEN=${config.sops.placeholder.${cfg.runner.tokenSecretName}}
          '';
          mode = "0400";
          owner = "root";
        };
      };
      systemd.services.gitea-backup = {
        script = ''
          mkdir -p /backup/gitea
          ${pkgs.gitea}/bin/gitea dump \
            --file /backup/gitea/gitea-$(date +%F).zip
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
          User = "gitea";
        };
      };
      systemd.services.gitea-runner-local = lib.mkIf cfg.runner.enable {
        # DynamicUser=true also forces PrivateTmp=yes with a tmpfs /tmp
        # (~800 MB on this Pi) that can't be turned off. Point TMPDIR into
        # the StateDirectory on ext4 so workflows using `mktemp -t` (e.g.
        # ephemeral Postgres) don't blow the cap.
        environment.TMPDIR = "/var/lib/gitea-runner/local/tmp";
        # DynamicUser=true forces noexec on StateDirectory; whitelist it
        # so jobs can exec binaries they install (playwright, QuestPdfSkia).
        serviceConfig.ExecPaths = [ "/var/lib/gitea-runner/local" ];
        serviceConfig.ExecStartPre = lib.mkAfter [
          (pkgs.writeShellScript "gitea-runner-local-mktmpdir" ''
            install -d -m 0700 "$TMPDIR"
          '')
        ];
      };
      systemd.services.gitea-runner-shared = lib.mkIf cfg.runner.shared.enable {
        after = [
          "gitea.service"
          "gitea-runner-shared-token.service"
        ];
        environment.TMPDIR = "/var/lib/gitea-runner/shared/tmp";
        requires = [
          "gitea.service"
          "gitea-runner-shared-token.service"
        ];
        # See gitea-runner-local for rationale.
        serviceConfig.ExecPaths = [ "/var/lib/gitea-runner/shared" ];
        serviceConfig.ExecStartPre = lib.mkAfter [
          (pkgs.writeShellScript "gitea-runner-shared-mktmpdir" ''
            install -d -m 0700 "$TMPDIR"
          '')
        ];
        wants = [ "gitea-runner-shared-token.service" ];
      };
      systemd.services.gitea-runner-shared-token = lib.mkIf cfg.runner.shared.enable {
        after = [ "gitea.service" ];
        description = "Generate registration token for the shared Gitea Actions runner";
        path = with pkgs; [
          coreutils
          curl
          jq
        ];
        requires = [ "gitea.service" ];
        script = ''
          set -euo pipefail

          token="$(cat ${config.sops.secrets.${cfg.actionsSecrets.patTokenSopsKey}.path})"
          registration_token="$(${pkgs.curl}/bin/curl \
            --silent --show-error --fail \
            -X POST \
            -H "Authorization: token $token" \
            "http://127.0.0.1:3000/api/v1/user/actions/runners/registration-token" | ${pkgs.jq}/bin/jq -r .token)"

          install -d -m 0755 "$(dirname ${cfg.runner.shared.tokenEnvPath})"
          printf 'TOKEN=%s\n' "$registration_token" > ${cfg.runner.shared.tokenEnvPath}
          chmod 0400 ${cfg.runner.shared.tokenEnvPath}
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
      };
      systemd.services.gitea-sync-actions-pat-token = lib.mkIf cfg.actionsSecrets.enablePatToken {
        after = [ "gitea.service" ];
        description = "Sync Gitea Actions PAT_TOKEN secret";
        path = with pkgs; [
          coreutils
          curl
          jq
        ];
        requires = [ "gitea.service" ];
        script = ''
          set -euo pipefail

          token_file=${config.sops.secrets.${cfg.actionsSecrets.patTokenSopsKey}.path}
          token="$(cat "$token_file")"

          repositories='${lib.concatStringsSep " " cfg.actionsSecrets.repositoryNames}'

          req_config="$(mktemp)"
          req_body="$(mktemp)"
          resp_body="$(mktemp)"
          trap 'rm -f "$req_config" "$req_body" "$resp_body"' EXIT

          printf 'header = "Authorization: token %s"\nheader = "Content-Type: application/json"\n' "$token" > "$req_config"

          jq -nc \
            --arg data "$token" \
            --arg description "managed by nixos module" \
            '{data:$data, description:$description}' > "$req_body"

          for repository in $repositories; do
            code="$(${pkgs.curl}/bin/curl \
              --silent --show-error \
              --output "$resp_body" \
              --write-out '%{http_code}' \
              --config "$req_config" \
              --request PUT \
              --data-binary @"$req_body" \
              "http://127.0.0.1:3000/api/v1/repos/${cfg.actionsSecrets.repositoryOwner}/$repository/actions/secrets/${cfg.actionsSecrets.patTokenSecretName}")"

            case "$code" in
              201|204) ;;
              *)
                cat "$resp_body"
                exit 1
                ;;
            esac
          done
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        wantedBy = [ "multi-user.target" ];
      };
      systemd.timers.gitea-backup = {
        description = "Run gitea backup every day.";
        timerConfig.OnCalendar = "daily";
        wantedBy = [ "timers.target" ];
      };
      users.users.gitea.openssh.authorizedKeys.keys = config.shared.authorizedKeys;
    })
  ];
  options.nixos.server.gitea = {
    actionsSecrets = {
      enablePatToken = lib.mkEnableOption "declarative PAT_TOKEN Actions secret" // {
        default = true;
      };
      patTokenSecretName = lib.mkOption {
        default = "PAT_TOKEN";
        description = "Actions secret name to create/update in Gitea.";
        type = lib.types.str;
      };
      patTokenSopsKey = lib.mkOption {
        default = "gitea-pat-token";
        description = "SOPS key name containing the PAT used for Actions auth.";
        type = lib.types.str;
      };
      repositoryName = lib.mkOption {
        default = "nix-configs";
        description = "Repository name where PAT_TOKEN should be managed.";
        type = lib.types.str;
      };
      repositoryNames = lib.mkOption {
        default = [ cfg.actionsSecrets.repositoryName ];
        description = "Repository names where PAT_TOKEN should be managed.";
        type = lib.types.listOf lib.types.str;
      };
      repositoryOwner = lib.mkOption {
        default = config.nixos.home.username;
        description = "Repository owner where PAT_TOKEN should be managed.";
        type = lib.types.str;
      };
    };
    enable = lib.mkEnableOption "gitea config" // {
      default = config.nixos.server.enable;
    };
    remoteRunner.enable = lib.mkEnableOption "runner-only mode against the tortinha Gitea";
    runner = {
      autoTokenFromSops = lib.mkEnableOption "automatic runner token file from SOPS" // {
        default = true;
      };
      enable = lib.mkEnableOption "self-hosted Gitea Actions runner" // {
        default = config.nixos.server.enable;
      };
      labels = lib.mkOption {
        default = [ "native:host" ];
        description = "Runner labels used by workflows in runs-on.";
        type = lib.types.listOf lib.types.str;
      };
      name = lib.mkOption {
        default = config.networking.hostName;
        description = "Name used when registering the runner in Gitea.";
        type = lib.types.str;
      };
      shared = {
        enable = lib.mkEnableOption "shared user-level Gitea Actions runner" // {
          default = false;
        };

        name = lib.mkOption {
          default = "${config.networking.hostName}-shared";
          description = "Name used when registering the shared user-level runner in Gitea.";
          type = lib.types.str;
        };

        tokenEnvPath = lib.mkOption {
          default = "/run/gitea-runner-shared.env";
          description = "Path to the generated TOKEN=<registration-token> env file for the shared runner.";
          type = lib.types.str;
        };
      };
      tokenFile = lib.mkOption {
        default = null;
        description = "Environment file containing TOKEN=<registration-token> when autoTokenFromSops is disabled.";
        example = "/run/secrets/gitea-runner.env";
        type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
      };
      tokenSecretName = lib.mkOption {
        default = "gitea-runner-token";
        description = "SOPS key name used for the runner registration token.";
        type = lib.types.str;
      };
      url = lib.mkOption {
        default = "http://127.0.0.1:3000";
        description = "Base URL of the Gitea instance used by the runner.";
        type = lib.types.str;
      };
    };
  };
}
