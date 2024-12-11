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

  home.packages = with pkgs;
    [
      mindustry

      alsa-utils
      kdePackages.kdenlive
      tiled
      lazygit
      htop
      bluez
      nerd-fonts.iosevka
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
      stylua
      love

      #qbittorrent
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
    ]
    ++ (import ./scripts {inherit pkgs;});

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
