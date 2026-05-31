{
  config,
  lib,
  myAuthorizedKeys,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.gitea;
in

{

  options.nixos.server.gitea = {
    enable = lib.mkEnableOption "gitea config" // {
      default = config.nixos.server.enable;
    };

    runner = {
      enable = lib.mkEnableOption "self-hosted Gitea Actions runner" // {
        default = config.nixos.server.enable;
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "Name used when registering the runner in Gitea.";
      };

      url = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:3000";
        description = "Base URL of the Gitea instance used by the runner.";
      };

      tokenFile = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
        default = null;
        example = "/run/secrets/gitea-runner.env";
        description = "Environment file containing TOKEN=<registration-token> when autoTokenFromSops is disabled.";
      };

      autoTokenFromSops = lib.mkEnableOption "automatic runner token file from SOPS" // {
        default = true;
      };

      tokenSecretName = lib.mkOption {
        type = lib.types.str;
        default = "gitea-runner-token";
        description = "SOPS key name used for the runner registration token.";
      };

      opencodeAuthSecretName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional SOPS key name containing an OpenCode auth.json payload to materialize in each runner data directory.";
      };

      labels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "native:host" ];
        description = "Runner labels used by workflows in runs-on.";
      };

      shared = {
        enable = lib.mkEnableOption "shared user-level Gitea Actions runner" // {
          default = false;
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "${config.networking.hostName}-shared";
          description = "Name used when registering the shared user-level runner in Gitea.";
        };

        tokenEnvPath = lib.mkOption {
          type = lib.types.str;
          default = "/run/gitea-runner-shared.env";
          description = "Path to the generated TOKEN=<registration-token> env file for the shared runner.";
        };
      };
    };

    actionsSecrets = {
      enablePatToken = lib.mkEnableOption "declarative PAT_TOKEN Actions secret" // {
        default = true;
      };

      repositoryOwner = lib.mkOption {
        type = lib.types.str;
        default = config.nixos.home.username;
        description = "Repository owner where PAT_TOKEN should be managed.";
      };

      repositoryName = lib.mkOption {
        type = lib.types.str;
        default = "nix-configs";
        description = "Repository name where PAT_TOKEN should be managed.";
      };

      repositoryNames = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ cfg.actionsSecrets.repositoryName ];
        description = "Repository names where PAT_TOKEN should be managed.";
      };

      patTokenSecretName = lib.mkOption {
        type = lib.types.str;
        default = "PAT_TOKEN";
        description = "Actions secret name to create/update in Gitea.";
      };

      patTokenSopsKey = lib.mkOption {
        type = lib.types.str;
        default = "gitea-pat-token";
        description = "SOPS key name containing the PAT used for Actions auth.";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = !(cfg.runner.enable && !cfg.runner.autoTokenFromSops && cfg.runner.tokenFile == null);
        message = "Set nixos.server.gitea.runner.tokenFile when nixos.server.gitea.runner.autoTokenFromSops is false and runner is enabled.";
      }
    ];

    sops.secrets = lib.mkMerge [
      (lib.mkIf (cfg.runner.enable && cfg.runner.autoTokenFromSops) {
        ${cfg.runner.tokenSecretName} = {
          owner = "root";
          mode = "0400";
        };
      })
      (lib.mkIf (cfg.runner.enable && cfg.runner.opencodeAuthSecretName != null) {
        ${cfg.runner.opencodeAuthSecretName} = {
          owner = "root";
          mode = "0400";
          sopsFile = ../../../secrets/opencode-auth.json;
        };
      })
    ];

    sops.templates = lib.mkIf (cfg.runner.enable && cfg.runner.autoTokenFromSops) {
      gitea-runner-env = {
        owner = "root";
        mode = "0400";
        content = ''
          TOKEN=${config.sops.placeholder.${cfg.runner.tokenSecretName}}
        '';
      };
    };

    systemd.services.gitea-sync-actions-pat-token = lib.mkIf cfg.actionsSecrets.enablePatToken {
      description = "Sync Gitea Actions PAT_TOKEN secret";
      after = [ "gitea.service" ];
      requires = [ "gitea.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      path = with pkgs; [
        coreutils
        curl
        jq
      ];
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
    };

    systemd.services.gitea-runner-shared-token = lib.mkIf cfg.runner.shared.enable {
      description = "Generate registration token for the shared Gitea Actions runner";
      after = [ "gitea.service" ];
      requires = [ "gitea.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = with pkgs; [
        coreutils
        curl
        jq
      ];
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
    };

    users.users.gitea.openssh.authorizedKeys.keys = myAuthorizedKeys;

    services.gitea = {
      enable = true;
      settings = {
        server = {
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
        };

        service = {
          DISABLE_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
        };

        attachment = {
          ENABLED = true;
          ALLOWED_TYPES = "*/*";
        };

        "repository.upload" = {
          ENABLED = true;
          ALLOWED_TYPES = "*/*";
        };

        actions.ENABLED = true;
      };
    };

    services.gitea-actions-runner.instances =
      lib.optionalAttrs cfg.runner.enable {
        local = {
          enable = true;
          name = cfg.runner.name;
          url = cfg.runner.url;
          tokenFile =
            if cfg.runner.autoTokenFromSops then
              config.sops.templates.gitea-runner-env.path
            else
              cfg.runner.tokenFile;
          labels = cfg.runner.labels;
          hostPackages = lib.mkOptionDefault [
            pkgs.nix
            pkgs.opencode
          ];
        };
      }
      // lib.optionalAttrs cfg.runner.shared.enable {
        shared = {
          enable = true;
          name = cfg.runner.shared.name;
          url = cfg.runner.url;
          tokenFile = cfg.runner.shared.tokenEnvPath;
          labels = cfg.runner.labels;
          hostPackages = lib.mkOptionDefault [
            pkgs.nix
            pkgs.opencode
          ];
        };
      };

    systemd.services.gitea-runner-local = lib.mkMerge [
      (lib.mkIf (cfg.runner.enable && cfg.runner.opencodeAuthSecretName != null) {
        environment = {
          XDG_CACHE_HOME = "/var/lib/gitea-runner/local/.cache";
          XDG_CONFIG_HOME = "/var/lib/gitea-runner/local/.config";
          XDG_DATA_HOME = "/var/lib/gitea-runner/local/.local/share";
        };
        serviceConfig.LoadCredential = [
          "opencode-auth.json:${config.sops.secrets."${cfg.runner.opencodeAuthSecretName}".path}"
        ];
        serviceConfig.ExecStartPre = lib.mkAfter [
          (pkgs.writeShellScript "gitea-runner-local-install-opencode" ''
            install -d -m 0700 "$XDG_DATA_HOME/opencode" "$XDG_CACHE_HOME"
            if [ -f "$CREDENTIALS_DIRECTORY/opencode-auth.json" ]; then
              install -m 0600 "$CREDENTIALS_DIRECTORY/opencode-auth.json" "$XDG_DATA_HOME/opencode/auth.json"
            fi
          '')
        ];
      })
      (lib.mkIf cfg.runner.enable {
        # DynamicUser=true forces noexec on StateDirectory; whitelist it
        # so jobs can exec binaries they install (playwright, QuestPdfSkia).
        serviceConfig.ExecPaths = [ "/var/lib/gitea-runner/local" ];
        # DynamicUser=true implies PrivateTmp=yes (~800 MB tmpfs); too small
        # for ephemeral Postgres under `mktemp -t`. Use host /tmp on ext4.
        serviceConfig.PrivateTmp = lib.mkForce false;
      })
    ];

    systemd.services.gitea-runner-shared = lib.mkMerge [
      (lib.mkIf (cfg.runner.shared.enable && cfg.runner.opencodeAuthSecretName != null) {
        environment = {
          XDG_CACHE_HOME = "/var/lib/gitea-runner/shared/.cache";
          XDG_CONFIG_HOME = "/var/lib/gitea-runner/shared/.config";
          XDG_DATA_HOME = "/var/lib/gitea-runner/shared/.local/share";
        };
        serviceConfig.LoadCredential = [
          "opencode-auth.json:${config.sops.secrets."${cfg.runner.opencodeAuthSecretName}".path}"
        ];
        serviceConfig.ExecStartPre = lib.mkAfter [
          (pkgs.writeShellScript "gitea-runner-shared-install-opencode" ''
            install -d -m 0700 "$XDG_DATA_HOME/opencode" "$XDG_CACHE_HOME"
            if [ -f "$CREDENTIALS_DIRECTORY/opencode-auth.json" ]; then
              install -m 0600 "$CREDENTIALS_DIRECTORY/opencode-auth.json" "$XDG_DATA_HOME/opencode/auth.json"
            fi
          '')
        ];
      })
      (lib.mkIf cfg.runner.shared.enable {
        after = [
          "gitea.service"
          "gitea-runner-shared-token.service"
        ];
        requires = [
          "gitea.service"
          "gitea-runner-shared-token.service"
        ];
        wants = [ "gitea-runner-shared-token.service" ];
        # See gitea-runner-local for rationale.
        serviceConfig.ExecPaths = [ "/var/lib/gitea-runner/shared" ];
        serviceConfig.PrivateTmp = lib.mkForce false;
      })
    ];

    systemd.timers.gitea-backup = {
      description = "Run gitea backup every day.";
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "daily";
    };

    systemd.services.gitea-backup = {
      serviceConfig = {
        User = "gitea";
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /backup/gitea
        ${pkgs.gitea}/bin/gitea dump \
          --file /backup/gitea/gitea-$(date +%F).zip
      '';
    };
    networking.firewall.allowedTCPPorts = [
      3000
      2222
    ];
  };
}
