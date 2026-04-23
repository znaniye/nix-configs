{
  flake,
  lib,
  modulesPath,
  nixos-raspberrypi,
  ...
}:
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
  nixos.server.gitea = {
    runner.opencodeAuthSecretName = "opencode-auth-json";
    runner.shared.enable = true;
    actionsSecrets.repositoryNames = [
      "nix-configs"
      "emit"
    ];
  };
  nixos.desktop = {
    sops.enable = true;
    tailscale.enable = true;
  };
  nixos.home.extraModules = {
    home-manager.dev.enable = false;
    home-manager.cli.codex.enable = false;
  };

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
