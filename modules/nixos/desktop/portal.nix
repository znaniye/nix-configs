{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixos.desktop.portal.enable = lib.mkEnableOption "desktop XDG portal config" // {
    default = config.nixos.desktop.wayland.enable;
  };

  config = lib.mkIf config.nixos.desktop.portal.enable {
    xdg.portal = {
      enable = true;
      config.common.default = "*";
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
    };
  };
}
