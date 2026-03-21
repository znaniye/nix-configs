{
  flake,
  config,
  lib,
  ...
}:
{
  imports = [
    ./boot
    ./dev
    ./networking
    flake.outputs.internal.sharedModules.default
    ./nix
    ./desktop
    ./home.nix
    ./server
    ./wsl.nix
  ];

  config.system.stateVersion = lib.mkDefault config.system.nixos.release;
}
