{pkgs, ...}: {
  imports = [
    ./programs
    ./services/polybar/polybar.nix
    ./services/picom.nix
  ];

  home = {
    username = "znaniye";
    homeDirectory = "/home/znaniye";
  };

  home.packages = with pkgs; [
    mindustry

    ldtk
    lazygit
    htop
    bluez
    nerdfonts
    ripgrep
    tokei
    discord
    telegram-desktop
    ranger
    krita
    aseprite
    fd
    tree
    fastfetch
    alacritty

    nix-tree
    nix-prefetch
    nix-prefetch-git
    nixpkgs-review
    nixfmt-rfc-style
    gh
    nil

    lua
    lua-language-server

    qbittorrent
    spotifyd
    firefox
    brightnessctl
    rofi
    unzip
    vlc
    networkmanager_dmenu
    flameshot
    spotify
    libreoffice-qt
    xclip
    pavucontrol
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
