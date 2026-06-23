{
  config,
  flake,
  lib,
  ...
}:
{
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
  ];

  config.system.stateVersion = lib.mkDefault config.system.nixos.release;
}
