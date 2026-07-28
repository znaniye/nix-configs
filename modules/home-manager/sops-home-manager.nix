{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.home-manager.sops;
in
{
  imports = [ flake.inputs.sops.homeManagerModule ];

  options.home-manager.sops = {
    enable = lib.mkEnableOption "home-manager sops config" // {
      default = config.home-manager.enable;
    };

    secrets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "anthropic-auth-token"
        "gh-token"
      ];
      description = "Secret keys from the default sops file materialized under $XDG_CONFIG_HOME/secrets, shared across all hosts.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets/var.yaml;
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      secrets = lib.genAttrs cfg.secrets (name: {
        path = "${config.xdg.configHome}/secrets/${name}";
      });
    };
  };
}
