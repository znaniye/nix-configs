{
  flake,
  ...
}:
let
  rpiPath = flake.inputs.nixos-raspberrypi.outPath;
  rpiOverlays = {
    bootloader = import (rpiPath + "/overlays/bootloader.nix");
    vendor-kernel = import (rpiPath + "/overlays/vendor-kernel.nix");
    vendor-firmware = import (rpiPath + "/overlays/vendor-firmware.nix");
    kernel-and-firmware = import (rpiPath + "/overlays/linux-and-firmware.nix");
    vendor-pkgs = import (rpiPath + "/overlays/vendor-pkgs.nix");
    jemalloc-page-size-16k = import (rpiPath + "/overlays/jemalloc-page-size-16k.nix");
  };

  rpiPkgsAarch64 = import flake.inputs.nixpkgs {
    system = "aarch64-linux";
    overlays = [
      rpiOverlays.bootloader
      rpiOverlays.vendor-kernel
      rpiOverlays.vendor-firmware
      rpiOverlays.kernel-and-firmware
      rpiOverlays.vendor-pkgs
    ];
  };

  nixosRaspberryPi = {
    overlays = rpiOverlays;
    packages.aarch64-linux = {
      inherit (rpiPkgsAarch64)
        raspberrypifw
        linuxPackages_rpi5
        linuxPackages_rpi4
        linuxPackages_rpi3
        linuxPackages_rpi02
        ;
    };
  };
in
{
  _module.args = {
    myAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbJhk5H0h7Oi79LSHLWfuffv6uFcuXtm77kewxrwQsD znaniye@golf"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtYBH7S5Hp8vvp4atduS6i8KWb22iuXZMnAYhvDIkCP znaniye@felix"
    ];

    "nixos-raspberrypi" = nixosRaspberryPi;
  };

  imports = [ ../../../modules/nixos ];
}
