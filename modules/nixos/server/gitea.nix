{
  config,
  pkgs,
  lib,
  myAuthorizedKeys,
  ...
}:

{

  options.nixos.server.gitea.enable = lib.mkEnableOption "gitea config" // {
    default = config.nixos.server.enable;
  };

  config = lib.mkIf config.nixos.server.gitea.enable {

    users.users.gitea.openssh.authorizedKeys.keys = myAuthorizedKeys;

    services.gitea = {
      enable = true;
      settings.server = {
        SSH_PORT = 2222;
        START_SSH_SERVER = true;
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
