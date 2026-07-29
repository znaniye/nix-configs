{ flake, lib, ... }:
{
  imports = [
    ../shared/meta.nix
    ../shared/theme.nix
    ./desktop.nix
    ./home.nix
    ./nix
    ./openssh.nix
    ./wireguard.nix
    flake.outputs.internal.sharedModules.system
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  programs.zsh.enable = lib.mkDefault true;

  system.stateVersion = lib.mkDefault 5;
}
