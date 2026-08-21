{
  flake,
  lib,
  modulesPath,
  nixos-raspberrypi,
  ...
}:
let
  golfCfg = flake.nixosConfigurations.golf.config;
  golfIp = lib.head (
    lib.splitString "/" golfCfg.networking.networkmanager.ensureProfiles.profiles.wired-golf.ipv4.address1
  );
in
{

  disabledModules = [
    (modulesPath + "/rename.nix")
  ];
  hardware.raspberry-pi.config = {
    all = {
      base-dt-params = {
        pciex1 = {
          enable = true;
          value = "on";
        };
        pciex1_gen = {
          enable = true;
          value = "3";
        };
      };
    };
  };
  imports = [
    (lib.mkAliasOptionModuleMD [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
    ./disko.nix
    #nixos-raspberrypi.nixosModules.sd-image
    flake.inputs.disko.nixosModules.disko
    nixos-raspberrypi.lib.inject-overlays
    nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
    nixos-raspberrypi.nixosModules.trusted-nix-caches
  ];
  networking.defaultGateway = "192.168.68.1";
  networking.dhcpcd.denyInterfaces = [ "end0" ];
  networking.interfaces.end0 = {
    ipv4.addresses = [
      {
        address = "192.168.68.111";
        prefixLength = 24;
      }
    ];
    useDHCP = false;
  };
  networking.nameservers = [
    "192.168.68.1"
    "1.1.1.1"
  ];
  nixos.desktop = {
    sops.enable = true;
    tailscale.enable = true;
  };
  nixos.home.extraModules = {
    home-manager.cli.codex.enable = false;
    home-manager.dev.enable = false;
  };
  nixos.server.enable = true;
  nixos.server.garnix.enable = false;
  nixos.server.gitea = {
    actionsSecrets.repositoryNames = [
      "nix-configs"
      "emit"
    ];
    runner.shared.enable = true;
  };
  nixos.server.pi-hole.enable = true;
  nixos.server.solidtime = {
    enable = true;
    superAdmins = [ "samuelwww17@gmail.com" ];
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  programs.ssh.knownHosts.golf = {
    hostNames = [
      "golf"
      golfIp
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWYfyw/IaVnBoGDHpb2CBa9M34Dty9PNl4wZhJ/VcwT";
  };
  swapDevices = [
    {
      device = "/var/swapfile";
      size = 8 * 1024;
    }
  ];
  # Authorize root@golf for remote aarch64 builds from x86 hosts.
  users.users.znaniye.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+nHM0J+aP4BsM+hkIv71WcTQ9y/JMJIDbA1JMA0/fH root@golf"
  ];
}
