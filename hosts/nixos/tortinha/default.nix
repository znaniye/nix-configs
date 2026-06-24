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

  disabledModules = [
    (modulesPath + "/rename.nix")
  ];

  nixos.server.enable = true;
  nixos.server.pi-hole.enable = true;
  nixos.server.solidtime = {
    enable = true;
    superAdmins = [ "samuelwww17@gmail.com" ];
  };
  nixos.server.gitea = {
    runner.opencodeAuthSecretName = "opencode-auth-json";
    runner.shared.enable = true;
    actionsSecrets.repositoryNames = [
      "nix-configs"
      "emit"
    ];
  };
  nixos.server.garnix = {
    enable = true;
    localActionRunner = false;
    actionRunnerHost = golfIp;
    remoteBuilders = [
      {
        name = "golf";
        hostname = golfIp;
        user = "nixremote";
        # sshKeyPath falls back to remoteBuilders.sshKeyPath, which garnix-secrets
        # stages from secrets.remoteBuilderSshPath (the action-runner key).
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        maxJobs = 8;
        speedFactor = 4;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
    ];
  };
  nixos.desktop = {
    sops.enable = true;
    tailscale.enable = true;
    # syncthing = {
    #   enable = true;
    #   deviceId = "ZWMG6VR-NMEPKRG-YGO7D2C-KILL6TI-SEZ6MOY-SOHPHU6-OTSGJOW-XVX4VQI";
    #   folder = "/var/lib/opencode/workdir";
    # };
  };
  nixos.home.extraModules = {
    home-manager.dev.enable = false;
    home-manager.cli.codex.enable = false;
  };

  users.users.znaniye.extraGroups = [ "opencode" ];

  # Authorize root@golf for remote aarch64 builds from x86 hosts.
  users.users.znaniye.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+nHM0J+aP4BsM+hkIv71WcTQ9y/JMJIDbA1JMA0/fH root@golf"
  ];

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

  networking.dhcpcd.denyInterfaces = [ "end0" ];
  networking.interfaces.end0 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.68.111";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = "192.168.68.1";
  networking.nameservers = [
    "192.168.68.1"
    "1.1.1.1"
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

  nixpkgs.hostPlatform = "aarch64-linux";
}
