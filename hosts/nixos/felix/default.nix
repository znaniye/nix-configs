{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nixos = {
    desktop = {
      enable = true;
      wayland.enable = true;
      #xserver.enable = true;
      wireguard = {
        address = "192.168.240.15/32";
        privateKeySecretName = "wireguard-private-key-felix";
      };
      # syncthing = {
      #   enable = true;
      #   deviceId = "PJFLXZG-5STGCRF-EYKSNGA-L36SDHW-QGKEYOG-KI6M7SC-VFI5QC6-FCYGAAJ";
      # };
    };
    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
        typescript.enable = true;
      };
    };
  };
}
