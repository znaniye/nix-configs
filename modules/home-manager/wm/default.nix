{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  cfg = config.home-manager.wm;
in
{
  imports = [
    ./i3.nix
    ./picom.nix
    ./polybar.nix
  ];

  options.home-manager.wm = {
    enable = lib.mkEnableOption "desktop config" // {
      default = true; # osConfig.nixos.desktop.enable or false;
    };
  };

  config = lib.mkIf cfg.enable { };

}
