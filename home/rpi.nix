{ pkgs, ... }:
{
  imports = [
    ./programs/nvim
    #./home/common.nix
    ./programs/zsh.nix
    ./programs/git.nix
  ];

  home.packages = with pkgs; [
    gitea
    nil
    nixfmt-rfc-style
  ];

  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
