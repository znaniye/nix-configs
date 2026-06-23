{
  config,
  lib,
  pkgs,
  attic,
  ...
}:

let
  cfg = config.nixos.attic-client;
  enabledCaches = lib.filterAttrs (_: cache: cache.enable) cfg.caches;
in
{
  options.nixos.attic-client = {
    enable = lib.mkEnableOption "attic binary cache client" // {
      default = false;
    };

    caches = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "this attic cache" // {
            default = true;
          };

          endpoint = lib.mkOption {
            type = lib.types.str;
            default = "https://cache.freedom.ind.br";
            description = "Attic server endpoint URL";
          };

          cacheName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Cache name used for attic login/push (defaults to the attribute name)";
          };
        };
      });
      default = {
        freedom = { };
      };
      description = "Attic caches to authenticate with";
      example = {
        freedom = { };
        personal = {
          endpoint = "https://cache.example.com";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      attic.packages.${pkgs.system}.attic-client
    ];

    sops.secrets = lib.mapAttrs' (
      name: _: lib.nameValuePair "attic-push-token-${name}" {
        owner = config.nixos.home.username;
        mode = "0400";
      }
    ) enabledCaches;

    systemd.services = lib.mapAttrs' (
      name: cache:
      let
        effectiveCacheName = if cache.cacheName == "" then name else cache.cacheName;
        secretPath = config.sops.secrets."attic-push-token-${name}".path;
      in
      lib.nameValuePair "attic-push-login-${name}" {
        description = "Login to attic cache ${name}";
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ attic.packages.${pkgs.system}.attic-client ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = config.nixos.home.username;
        };
        script = ''
          attic login ${effectiveCacheName} ${cache.endpoint} "$(cat ${secretPath})"
        '';
      }
    ) enabledCaches;

  };
}
