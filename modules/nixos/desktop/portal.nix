{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.nixos.desktop.portal.enable {
    xdg.portal = {
      config.common.default = "*";
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
    };
  };
  options.nixos.desktop.portal.enable = lib.mkEnableOption "desktop XDG portal config" // {
    default = config.nixos.desktop.wayland.enable;
  };
}
