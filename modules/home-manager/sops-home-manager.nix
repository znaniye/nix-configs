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

  options.home-manager.sops.enable = lib.mkEnableOption "home-manager sops config" // {
    default = config.home-manager.enable;
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets/var.yaml;
      age.keyFile = "/home/znaniye/.config/sops/age/keys.txt";
    };
  };
}
