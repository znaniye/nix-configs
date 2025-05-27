{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    lazygit
    starship
    htop
    nerd-fonts.iosevka
    ripgrep
    tokei
    ranger
    fd
    unzip
    rar
    xclip
    fastfetch
    direnv

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
