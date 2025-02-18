{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    lazygit
    htop
    nerd-fonts.iosevka
    ripgrep
    tokei
    ranger
    fd
    tree
    unzip
    xclip
    fastfetch

    nix-tree
    nix-prefetch
    nix-prefetch-git
    nixpkgs-review
    nixfmt-rfc-style
    gh
    nil

    lua
    lua-language-server
    stylua
    love
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";

}
