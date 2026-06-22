{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nixos = {
    desktop = {
      enable = true;
      virtualization.enable = true;
      tailscale.ossystems.enable = true;
      wayland.enable = true;
      flatpak.enable = true;
      wireguard = {
        address = "192.168.240.8/32";
        privateKeySecretName = "wireguard-private-key-golf";
      };
      # syncthing = {
      #   enable = true;
      #   deviceId = "U5RIZFP-YTCUPJ3-ZH2LKC6-EVLRLZK-7THXOGE-P6FYCQU-2OS7HXR-2A44LQC";
      # };
    };

    dev.postgres.enable = true;
    dev.emitApp.enable = true;

    server.garnix.enable = false;
    server.garnixRunner.enable = true;

    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
        dotnet.enable = true;
        python.enable = true;
        haskell.enable = true;
        typescript.enable = true;
      };
    };
  };

  services.hardware.deepcool-digital-linux.enable = true;

  users.users.nixremote = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2DPx198YXU9f0dCAwWhPBIVswQ/H9KVuaXe19Brhme garnix-action-runner@golf"
    ];
  };

  nix.settings.trusted-users = [ "nixremote" ];

  networking.networkmanager.ensureProfiles.profiles.wired-golf = {
    connection = {
      id = "wired-golf";
      type = "ethernet";
      interface-name = "eno1";
      autoconnect = true;
      autoconnect-priority = 100;
    };
    ipv4 = {
      method = "manual";
      address1 = "192.168.68.107/24,192.168.68.1";
      dns = "192.168.68.1;1.1.1.1";
    };
    ipv6.method = "ignore";
  };
}
