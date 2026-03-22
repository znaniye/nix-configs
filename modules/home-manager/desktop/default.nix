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
  ];

  options.home-manager.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default = lib.attrByPath [ "nixos" "desktop" "enable" ] false osCfg;
    };
  };

  config = lib.mkIf cfg.enable {

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
  };
}
