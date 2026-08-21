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
  config = lib.mkIf cfg.enable {
    sops = {
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      defaultSopsFile = ../../secrets/var.yaml;
      secrets = lib.genAttrs cfg.secrets (name: {
        path = "${config.xdg.configHome}/secrets/${name}";
      });
    };
  };
  imports = [ flake.inputs.sops.homeManagerModule ];
  options.home-manager.sops = {
    enable = lib.mkEnableOption "home-manager sops config" // {
      default = config.home-manager.enable;
    };

    secrets = lib.mkOption {
      default = [
        "anthropic-auth-token"
        "gh-token"
        "gitea-smace-token"
      ];
      description = "Secret keys from the default sops file materialized under $XDG_CONFIG_HOME/secrets, shared across all hosts.";
      type = lib.types.listOf lib.types.str;
    };
  };
}
