{
  config,
  flake,
  pkgs,
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
    ./disko.nix
    (lib.mkAliasOptionModuleMD [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
  ];

  disabledModules = [
    (modulesPath + "/rename.nix")
  ];

  nixos.desktop = {
    sops.enable = true;
    tailscale.enable = true;
  };

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

  programs.direnv.enable = true;

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  environment.systemPackages = with pkgs; [ git ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = config.system.nixos.release;
}
