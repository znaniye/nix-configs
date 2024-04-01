{pkgs, ...}: {
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

    htop
    bluez
    nerdfonts
    ripgrep
    discord
    telegram-desktop
    element-desktop
    dbeaver
    obsidian
    ranger
    krita
    hplip
    aseprite
    godot_4
    blender
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
    alejandra
    gh
    nil

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
