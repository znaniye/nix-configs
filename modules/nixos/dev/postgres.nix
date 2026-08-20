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
  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = cfg.tcpip.enable;
      package = cfg.package;
      settings = {
        password_encryption = cfg.settings.passwordEncryption;
      }
      // lib.optionalAttrs cfg.tcpip.enable {
        listen_addresses = cfg.settings.listenAddresses;
        port = cfg.settings.port;
      };
    };
  };
  options.nixos.dev.postgres = {
    enable = lib.mkEnableOption "PostgreSQL development config" // {
      default = config.nixos.dev.enable;
    };
    package = lib.mkOption {
      default = pkgs.postgresql_18;
      description = "PostgreSQL package to use.";
      type = lib.types.package;
    };
    settings = {
      listenAddresses = lib.mkOption {
        default = "*";
        description = "Value for postgresql listen_addresses.";
        type = lib.types.str;
      };
      passwordEncryption = lib.mkOption {
        default = "scram-sha-256";
        description = "Value for postgresql password_encryption.";
        type = lib.types.str;
      };
      port = lib.mkOption {
        default = 5432;
        description = "TCP port for PostgreSQL.";
        type = lib.types.port;
      };
    };
    tcpip.enable = lib.mkEnableOption "PostgreSQL TCP/IP listener" // {
      default = true;
    };
  };
}
