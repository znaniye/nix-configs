{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.dev.postgres;
in
{
  options.nixos.dev.postgres = {
    enable = lib.mkEnableOption "PostgreSQL development config" // {
      default = config.nixos.dev.enable;
    };

    tcpip.enable = lib.mkEnableOption "PostgreSQL TCP/IP listener" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_18;
      description = "PostgreSQL package to use.";
    };

    settings = {
      listenAddresses = lib.mkOption {
        type = lib.types.str;
        default = "*";
        description = "Value for postgresql listen_addresses.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 5432;
        description = "TCP port for PostgreSQL.";
      };

      passwordEncryption = lib.mkOption {
        type = lib.types.str;
        default = "scram-sha-256";
        description = "Value for postgresql password_encryption.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = cfg.package;

      enableTCPIP = cfg.tcpip.enable;

      settings = {
        password_encryption = cfg.settings.passwordEncryption;
      }
      // lib.optionalAttrs cfg.tcpip.enable {
        listen_addresses = cfg.settings.listenAddresses;
        port = cfg.settings.port;
      };
    };
  };
}
