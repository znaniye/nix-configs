{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  common = import ./common.nix { inherit pkgs inputs; };
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
      #mindustry
      #dotnetCorePackages.dotnet_9.sdk # For Godot-Mono VSCode-Extension CSharp
      #itch
      alsa-utils
      ncdu
      calibre
      #kdePackages.kdenlive
      #tiled
      bluez
      godot-mono
      blender
      nerd-fonts.iosevka
      discord
      telegram-desktop
      obs-studio
      krita
      #aseprite
      alacritty
      #code-cursor
      tor-browser

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

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
