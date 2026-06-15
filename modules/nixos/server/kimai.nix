{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.server.kimai;
in

{

  options.nixos.server.kimai = {
    enable = lib.mkEnableOption "kimai time-tracker config" // {
      default = config.nixos.server.enable;
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "kimai.znaniye.xyz";
      description = "Public hostname served for Kimai (matched against the Host header from cloudflared).";
    };
  };

  config = lib.mkIf cfg.enable {

    services.kimai.sites.${cfg.domain} = {
      database.createLocally = true;

      settings.kimai = {
        user.registration = false;
        defaults = {
          customer = {
            timezone = "America/Sao_Paulo";
            country = "BR";
            currency = "BRL";
          };
          user = {
            timezone = "America/Sao_Paulo";
            language = "pt_BR";
          };
        };
      };
    };
  };
}
