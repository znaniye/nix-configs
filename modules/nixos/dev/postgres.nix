{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.dev.postgres;
  emitAppCfg = cfg.emitApp;
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

    emitApp = {
      enable = lib.mkEnableOption "emit-app local database bootstrap" // {
        default = false;
      };

      database = lib.mkOption {
        type = lib.types.str;
        default = "emit_app";
        description = "Database name used by emit-app.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "emit_app";
        description = "Role name used by emit-app.";
      };

      authentication.enable = lib.mkEnableOption "emit-app localhost auth rules" // {
        default = true;
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

      ensureDatabases = lib.optionals emitAppCfg.enable [ emitAppCfg.database ];
      ensureUsers = lib.optionals emitAppCfg.enable [
        {
          name = emitAppCfg.user;
          ensureDBOwnership = true;
        }
      ];

      authentication = lib.mkIf (emitAppCfg.enable && emitAppCfg.authentication.enable) (
        lib.mkOverride 10 ''
          # TYPE  DATABASE  USER      ADDRESS           METHOD
          local   all       all                         peer
          host  ${emitAppCfg.database}  ${emitAppCfg.user}  127.0.0.1/32  ${cfg.settings.passwordEncryption}
          host  ${emitAppCfg.database}  ${emitAppCfg.user}  ::1/128       ${cfg.settings.passwordEncryption}
        ''
      );
    };
  };
}
