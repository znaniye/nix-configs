{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.emit-api;
in
{
  options = {

    services.emit-api = {

      enable = mkEnableOption "Emit Api";

      package = mkPackageOption pkgs "emit-api" { };

      envFile = mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/run/secrets/rendered/.env";
        description = "Environment  file to set up environment variables for `Emit.Api`";
      };

    };
  };

  config = mkIf cfg.enable {

    systemd.services.emit-api = {
      description = "Emit Api";

      wantedBy = [ "multi-user.target" ];
      requires = [ "local-fs.target" ];
      wants = [ "network-online.target" ];
      after = [
        "local-fs.target"
        "network.target"
        "network-online.target"
        "time-sync.target"
      ];

      #environment = {};

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/Emit.Api";
        EnvironmentFile = mkIf (cfg.envFile != null) cfg.envFile;
      };
    };
  };
}
