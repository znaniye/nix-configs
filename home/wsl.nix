{ pkgs, ... }:
{
  imports = [
    ./programs/nvim
    ./programs/git.nix
    ./programs/zsh.nix
    ./common.nix
  ];

  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
  };

  #home.packages = with pkgs; [];
}
