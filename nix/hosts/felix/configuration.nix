{
  flake,
  hostName,
  lib,
  ...
}@args:
{
  networking.hostName = lib.mkDefault hostName;

  imports = [
    flake.nixosModules.default
    (import ../../../hosts/nixos/felix/default.nix args)
  ];
}
