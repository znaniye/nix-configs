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
      wireguard = {
        address = "192.168.240.9/32";
        privateKeySecretName = "wireguard-private-key-felix";
      };
    };
    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
      };
    };
  };
}
