{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nixos = {
    desktop = {
      enable = true;
      #wayland.enable = true;
      xserver.enable = true;
    };
    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
      };
    };
  };
}
