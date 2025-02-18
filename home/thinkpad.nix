{ pkgs, lib, ... }:
let
  common = import ./common.nix { inherit pkgs; };
in

{
  imports = [
    ./programs
    ./services/polybar/polybar.nix
    ./services/picom.nix
  ];

  home = {
    username = lib.mkDefault "znaniye";
    homeDirectory = lib.mkDefault "/home/znaniye";
  };

  home.packages =
    with pkgs;
    common.home.packages
    ++ [
      mindustry

      alsa-utils
      kdePackages.kdenlive
      tiled
      bluez
      nerd-fonts.iosevka
      discord
      telegram-desktop
      krita
      aseprite
      alacritty

      #qbittorrent
      spotifyd
      firefox
      brightnessctl
      rofi
      vlc
      networkmanager_dmenu
      flameshot
      spotify
      libreoffice-qt
      pavucontrol
    ]
    ++ (import ./scripts { inherit pkgs; });
}
