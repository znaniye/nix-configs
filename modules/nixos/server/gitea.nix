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
      enable = lib.mkEnableOption "self-hosted Gitea Actions runner";

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
        description = "Environment file containing TOKEN=<registration-token>.";
      };

      labels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "native:host" ];
        description = "Runner labels used by workflows in runs-on.";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = !(cfg.runner.enable && cfg.runner.tokenFile == null);
        message = "Set nixos.server.gitea.runner.tokenFile when nixos.server.gitea.runner.enable is true.";
      }
    ];

    users.users.gitea.openssh.authorizedKeys.keys = myAuthorizedKeys;

    services.gitea = {
      enable = true;
      settings = {
        server = {
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
        };

        actions.ENABLED = true;
      };
    };

    services.gitea-actions-runner.instances = lib.mkIf cfg.runner.enable {
      local = {
        enable = true;
        name = cfg.runner.name;
        url = cfg.runner.url;
        tokenFile = cfg.runner.tokenFile;
        labels = cfg.runner.labels;
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
