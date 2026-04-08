{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nixos = {
    desktop = {
      enable = true;
      virtualization.enable = true;
      wayland.enable = true;
      flatpak.enable = true;
      wireguard = {
        address = "192.168.240.8/32";
        privateKeySecretName = "wireguard-private-key-golf";
      };
    };

    dev.postgres = {
      enable = true;
      emitApp = {
        enable = true;
      };
    };

    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
        dotnet.enable = true;
      };
    };
  };

  services.hardware.deepcool-digital-linux.enable = true;
}
