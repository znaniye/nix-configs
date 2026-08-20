{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];
  networking.networkmanager.ensureProfiles.profiles.wired-golf = {
    connection = {
      autoconnect = true;
      autoconnect-priority = 100;
      id = "wired-golf";
      interface-name = "eno1";
      type = "ethernet";
    };
    ipv4 = {
      address1 = "192.168.68.107/24,192.168.68.1";
      dns = "192.168.68.1;1.1.1.1";
      method = "manual";
    };
    ipv6.method = "ignore";
  };
  nix.settings.trusted-users = [ "nixremote" ];
  nixos = {
    desktop = {
      enable = true;
      flatpak.enable = true;
      syncthing.enable = true;
      tailscale.ossystems.enable = true;
      virtualization.enable = true;
      wayland.enable = true;
      wireguard = {
        address = "192.168.240.8/32";
        privateKeySecretName = "wireguard-private-key-golf";
      };
      zmk.enable = true;
    };
    dev.emitApp.enable = true;
    dev.postgres.enable = true;
    home.extraModules = {
      home-manager.dev = {
        claude-code.intervalsMcp.enable = true;
        claude-code.stravaMcp.enable = true;
        dotnet.enable = true;
        go.enable = true;
        haskell.enable = true;
        lua.enable = true;
        ocaml.enable = true;
        python.enable = true;
        typescript.enable = true;
      };
    };
    server.garnix.enable = false;
    server.garnixRunner.enable = true;
    server.gitea.remoteRunner.enable = true;
    server.k3s.enable = true;
  };
  nixos.attic-client.enable = true;
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 5;
  };
  services.hardware.deepcool-digital-linux.enable = true;
  users.users.nixremote = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2DPx198YXU9f0dCAwWhPBIVswQ/H9KVuaXe19Brhme garnix-action-runner@golf"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmroI8gBPj2J2JxGZZYFhQCUYeU0FKZTK6kgP+9gmFZ root@felix"
    ];
  };
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
}
