{
  config,
  lib,
  pkgs,
  ...
}:
{

  config = lib.mkIf config.nixos.desktop.wayland.enable {
    environment.systemPackages = with pkgs; [ wl-clipboard ];
    programs.niri.enable = true;
  };
  options.nixos.desktop.wayland.enable = lib.mkEnableOption "wayland cfg" // {
    default = false;
  };
}
