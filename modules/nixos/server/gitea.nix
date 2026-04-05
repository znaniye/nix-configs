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

      labels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "native:host" ];
        description = "Runner labels used by workflows in runs-on.";
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

    sops.secrets = lib.mkIf (cfg.runner.enable && cfg.runner.autoTokenFromSops) {
      ${cfg.runner.tokenSecretName} = {
        owner = "root";
        mode = "0400";
      };
    };

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

        req_config="$(mktemp)"
        req_body="$(mktemp)"
        resp_body="$(mktemp)"
        trap 'rm -f "$req_config" "$req_body" "$resp_body"' EXIT

        printf 'header = "Authorization: token %s"\nheader = "Content-Type: application/json"\n' "$token" > "$req_config"

        jq -nc \
          --arg data "$token" \
          --arg description "managed by nixos module" \
          '{data:$data, description:$description}' > "$req_body"

        code="$(${pkgs.curl}/bin/curl \
          --silent --show-error \
          --output "$resp_body" \
          --write-out '%{http_code}' \
          --config "$req_config" \
          --request PUT \
          --data-binary @"$req_body" \
          "http://127.0.0.1:3000/api/v1/repos/${cfg.actionsSecrets.repositoryOwner}/${cfg.actionsSecrets.repositoryName}/actions/secrets/${cfg.actionsSecrets.patTokenSecretName}")"

        case "$code" in
          201|204) ;;
          *)
            cat "$resp_body"
            exit 1
            ;;
        esac
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

        actions.ENABLED = true;
      };
    };

    services.gitea-actions-runner.instances = lib.mkIf cfg.runner.enable {
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
        hostPackages = lib.mkOptionDefault [ pkgs.nix ];
      };
    };

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
