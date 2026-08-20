{ config, lib, ... }:
{
  config = lib.mkIf config.nixos.desktop.flatpak.enable {
    services.flatpak.enable = true;
  };
  options.nixos.desktop.flatpak.enable = lib.mkEnableOption "desktop Flatpak config" // {
    default = false;
  };
}
