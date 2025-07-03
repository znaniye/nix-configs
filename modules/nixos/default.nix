{ flake, ... }:
{
  imports = [
    flake.outputs.internal.sharedModules.default
    ./nix
    ./desktop
    ./home.nix
  ];
}
