{
  flake,
  lib,
  modulesPath,
  ...
}:
let
  rpiPath = flake.inputs.nixos-raspberrypi.outPath;
in
{

  imports = [
    (lib.mkAliasOptionModule [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
    ./disko.nix
    #nixos-raspberrypi.nixosModules.sd-image
    flake.inputs.disko.nixosModules.disko
    (rpiPath + "/modules/raspberry-pi-5")
    (rpiPath + "/modules/display-vc4.nix")
    (rpiPath + "/modules/trusted-nix-caches.nix")
  ];

  nixpkgs.overlays = [
    (import (rpiPath + "/overlays/bootloader.nix"))
    (import (rpiPath + "/overlays/vendor-kernel.nix"))
    (import (rpiPath + "/overlays/vendor-firmware.nix"))
    (import (rpiPath + "/overlays/linux-and-firmware.nix"))
    (import (rpiPath + "/overlays/vendor-pkgs.nix"))
  ];

  disabledModules = [
    (modulesPath + "/rename.nix")
  ];

  nixos.server.enable = true;
  nixos.desktop = {
    sops.enable = true;
    tailscale.enable = true;
  };
  nixos.home.extraModules.home-manager.dev.enable = false;

  boot.loader.raspberry-pi.bootloader = "kernel";

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
