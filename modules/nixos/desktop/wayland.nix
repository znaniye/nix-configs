{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.nixos.desktop.wayland.enable = lib.mkEnableOption "wayland cfg" // {
    default = false;
  };

  config = lib.mkIf config.nixos.desktop.wayland.enable {
    services.displayManager.gdm.enable = true;

    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
    };
  };
}
