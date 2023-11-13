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
    (pkgs.factorio.override {
      username = "znaniye";
      token = "903c217867449653fcb687a0b149b6";
      versionsJson = ./configs/factorio/versions.json;
    })
    mindustry

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

    #android-studio
    #android-tools
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "22.11";
}
