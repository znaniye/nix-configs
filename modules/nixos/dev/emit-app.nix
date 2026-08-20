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
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pgCfg.enable;
        message = "nixos.dev.emitApp requires nixos.dev.postgres.enable = true.";
      }
    ];

    services.postgresql = {
      authentication = lib.mkIf cfg.authentication.enable (
        lib.mkOverride 10 ''
          # TYPE  DATABASE  USER      ADDRESS           METHOD
          local   all       all                         peer
          host  ${cfg.database}  ${cfg.user}  127.0.0.1/32  ${pgCfg.settings.passwordEncryption}
          host  ${cfg.database}  ${cfg.user}  ::1/128       ${pgCfg.settings.passwordEncryption}
        ''
      );
      ensureDatabases = [ cfg.database ];
      ensureUsers = [
        {
          ensureDBOwnership = true;
          name = cfg.user;
        }
      ];
    };
  };
  options.nixos.dev.emitApp = {
    authentication.enable = lib.mkEnableOption "emit-app localhost auth rules" // {
      default = true;
    };
    database = lib.mkOption {
      default = "emit_app";
      description = "Database name used by emit-app.";
      type = lib.types.str;
    };
    enable = lib.mkEnableOption "emit-app local database bootstrap" // {
      default = false;
    };
    user = lib.mkOption {
      default = "emit_app";
      description = "Role name used by emit-app.";
      type = lib.types.str;
    };
  };
}
