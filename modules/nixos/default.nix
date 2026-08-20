{
  config,
  flake,
  lib,
  ...
}:
{
  config.system.stateVersion = lib.mkDefault config.system.nixos.release;
  imports = [
    ./attic-client
    ./boot
    ./desktop
    ./dev
    ./home.nix
    ./networking
    ./nix
    ./server
    ./wsl.nix
    flake.outputs.internal.sharedModules.default
    flake.outputs.internal.sharedModules.system
  ];
}
