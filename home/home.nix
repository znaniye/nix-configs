{ pkgs, ... }:
{
  imports = [
    ./programs
    ./services/polybar.nix
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
    teams-for-linux
    appflowy
    htop
    bluez
    nerdfonts
    ripgrep
    tokei
    discord
    telegram-desktop
    element-desktop
    ranger
    krita
    aseprite
    godot_4
    syncthing
    fd
    ix
    tree
    neofetch
    alacritty
    jetbrains.idea-community

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
    sonic-pi
    firefox
    brightnessctl
    rofi
    unzip
    vlc
    networkmanager_dmenu
    flameshot
    spotify
    libreoffice-qt
    mindustry
    xclip
    pavucontrol
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "22.11";
}
