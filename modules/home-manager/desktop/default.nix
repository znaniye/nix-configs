{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.wm;
  osCfg = if osConfig == null then { } else osConfig;
in
{
  imports = [
    ./alacritty.nix
    ./zellij.nix
    ./herdr.nix
    ./wallpaper.nix
  ];

  options.home-manager.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default =
        lib.attrByPath [ "nixos" "desktop" "enable" ] false osCfg
        || lib.attrByPath [ "darwin" "desktop" "enable" ] false osCfg;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

    programs.mangohud = {
      enable = true;
      settings = {
        cpu_stats = true;
        cpu_temp = true;
        gpu_stats = true;
        gpu_temp = true;
        fps = true;
        frametime = true;
      };
    };

    home.packages = with pkgs; [
      pencil
      firefox
      spotify
      discord
      telegram-desktop
      xfce.thunar
      foliate
      dunst
      zathura
      godot
      pavucontrol
      prismlauncher
      openfreebuds
      zellij
      vlc
    ];
    })

    (lib.mkIf (config.home-manager.desktop.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      home.packages = with pkgs; [
        spotify
        vesktop
        telegram-desktop
      ];
    })
  ];
}
