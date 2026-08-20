{
  attic,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixos.attic-client;
  enabledCaches = lib.filterAttrs (_: cache: cache.enable) cfg.caches;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      attic.packages.${pkgs.system}.attic-client
    ];

    sops.secrets = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "attic-push-token-${name}" {
        mode = "0400";
        owner = config.nixos.home.username;
      }
    ) enabledCaches;

    systemd.services = lib.mapAttrs' (
      name: cache:
      let
        effectiveCacheName = if cache.cacheName == "" then name else cache.cacheName;
        secretPath = config.sops.secrets."attic-push-token-${name}".path;
      in
      lib.nameValuePair "attic-push-login-${name}" {
        after = [ "network-online.target" ];
        description = "Login to attic cache ${name}";
        path = [ attic.packages.${pkgs.system}.attic-client ];
        script = ''
          attic login ${effectiveCacheName} ${cache.endpoint} "$(cat ${secretPath})"
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
          User = config.nixos.home.username;
        };
        wantedBy = [ "multi-user.target" ];
      }
    ) enabledCaches;

  };
  options.nixos.attic-client = {
    caches = lib.mkOption {
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
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            cacheName = lib.mkOption {
              default = "";
              description = "Cache name used for attic login/push (defaults to the attribute name)";
              type = lib.types.str;
            };
            enable = lib.mkEnableOption "this attic cache" // {
              default = true;
            };
            endpoint = lib.mkOption {
              default = "https://cache.freedom.ind.br";
              description = "Attic server endpoint URL";
              type = lib.types.str;
            };
          };
        }
      );
    };
    enable = lib.mkEnableOption "attic binary cache client" // {
      default = false;
    };
  };
}
