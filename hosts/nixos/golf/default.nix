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
      syncthing = {
        enable = true;
        deviceId = "U5RIZFP-YTCUPJ3-ZH2LKC6-EVLRLZK-7THXOGE-P6FYCQU-2OS7HXR-2A44LQC";
      };
    };

    dev.postgres = {
      enable = true;
      emitApp = {
        enable = true;
      };
    };

    server.garnix.enable = true;

    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
        dotnet.enable = true;
        python.enable = true;
        haskell.enable = true;
      };
    };
  };

  services.hardware.deepcool-digital-linux.enable = true;
}
