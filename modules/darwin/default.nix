{ lib, ... }:
{
  imports = [
    ../shared/meta.nix
    ../shared/theme.nix
    ./home.nix
    ./nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  programs.zsh.enable = lib.mkDefault true;

  system.stateVersion = lib.mkDefault 5;
}
