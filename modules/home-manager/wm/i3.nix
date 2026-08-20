{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  osCfg = if osConfig == null then { } else osConfig;
in
{
  config = lib.mkIf config.home-manager.wm.i3.enable {

    home.packages = with pkgs; [
      dunst
      flameshot
    ];

    xsession.windowManager.i3 = {
      config = rec {
        bars = [ ];
        gaps = {
          inner = 5;
          outer = 5;
        };
        keybindings = lib.mkOptionDefault {
          "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
          "${modifier}+Shift+p" = "exec ${pkgs.flameshot}/bin/flameshot gui";
          "${modifier}+Shift+x" = "exec systemctl suspend";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -modi drun -show drun";
          "XF86AudioLowerVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 4%-";
          "XF86AudioMute" = "exec ${pkgs.alsa-utils}/bin/amixer set Master toggle";
          "XF86AudioRaiseVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 4%+";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 4%-";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 4%+";
        };
        modifier = "Mod4";
        startup = [
          {
            always = true;
            command = "exec i3-msg workspace 1";
            notification = false;
          }
          {
            always = true;
            command = "systemctl --user restart polybar.service";
            notification = false;
          }
          {
            always = true;
            command = "picom";
            notification = false;
          }
          {
            always = true;
            command = "${pkgs.feh}/bin/feh --bg-scale ${config.shared.theme.wallpaper}";
            notification = false;
          }
        ];
        window.border = 0;
      };
      enable = true;
      extraConfig = ''
        default_border pixel 0
      '';
    };
  };
  options.home-manager.wm.i3.enable = lib.mkEnableOption "i3 config" // {
    default = lib.attrByPath [ "nixos" "desktop" "xserver" "enable" ] false osCfg;
  };
}
