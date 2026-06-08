{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.dev.emitApp;
  pgCfg = config.nixos.dev.postgres;
in
{
  options.nixos.dev.emitApp = {
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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pgCfg.enable;
        message = "nixos.dev.emitApp requires nixos.dev.postgres.enable = true.";
      }
    ];

    services.postgresql = {
      ensureDatabases = [ cfg.database ];
      ensureUsers = [
        {
          name = cfg.user;
          ensureDBOwnership = true;
        }
      ];

      authentication = lib.mkIf cfg.authentication.enable (
        lib.mkOverride 10 ''
          # TYPE  DATABASE  USER      ADDRESS           METHOD
          local   all       all                         peer
          host  ${cfg.database}  ${cfg.user}  127.0.0.1/32  ${pgCfg.settings.passwordEncryption}
          host  ${cfg.database}  ${cfg.user}  ::1/128       ${pgCfg.settings.passwordEncryption}
        ''
      );
    };
  };
}
