{
  config,
  flake,
  lib,
  nixos-raspberrypi,
  modulesPath,
  ...
}:
{

  imports = [
    nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
    #nixos-raspberrypi.nixosModules.sd-image
    nixos-raspberrypi.lib.inject-overlays
    nixos-raspberrypi.nixosModules.trusted-nix-caches
    flake.inputs.disko.nixosModules.disko
    flake.inputs.comin.nixosModules.comin
    ./disko.nix
    (lib.mkAliasOptionModuleMD [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
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

  programs.zsh.enable = true;

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

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = config.system.nixos.release;
}
