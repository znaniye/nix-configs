{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.home-manager.wm;
in
{
  imports = [ ./alacritty.nix ];

  options.home-manager.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default = osConfig.nixos.desktop.enable or false;
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
      discord
      telegram-desktop
      xfce.thunar
      foliate
      dunst
      zathura
      godot
      pavucontrol
      (openfreebuds.overrideAttrs (_: {
        postInstall = ''
          mkdir -p  $out/share/applications
          mv openfreebuds_qt/assets/pw.mmk.OpenFreebuds.desktop $out/share/applications
        '';
      }))
    ];
  };
}
