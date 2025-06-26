{ pkgs, ... }:
{
  imports = [
    #./home/programs/nvim
    #./home/common.nix
    ./zsh.nix
    ./git.nix
  ];

  home.packages = with pkgs; [ gitea ];

  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
