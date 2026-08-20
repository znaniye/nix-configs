{
  config,
  lib,
  osConfig,
  ...
}:
let
  cfg = config.home-manager.wm;
  osCfg = if osConfig == null then { } else osConfig;
in
{
  config = lib.mkIf cfg.enable { };
  imports = [
    ./dunst.nix
    ./fuzzel.nix
    ./gtk.nix
    ./i3.nix
    ./niri
    ./picom.nix
    ./polybar.nix
    ./waybar
  ];
  options.home-manager.wm = {
    enable = lib.mkEnableOption "desktop config" // {
      default = lib.attrByPath [ "nixos" "desktop" "enable" ] false osCfg;
    };
  };

}
