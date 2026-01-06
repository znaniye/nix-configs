{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

{
  options.home-manager.wm.i3.enable = lib.mkEnableOption "i3 config" // {
    default = osConfig.nixos.desktop.xserver.enable or false;
  };

  config = lib.mkIf config.home-manager.wm.i3.enable {

    home.packages = with pkgs; [
      dunst
      flameshot
    ];

    xsession.windowManager.i3 = {
      enable = true;

      config = rec {
        modifier = "Mod4";
        bars = [ ];

        window.border = 0;

        gaps = {
          inner = 5;
          outer = 5;
        };

        keybindings = lib.mkOptionDefault {
          "XF86AudioMute" = "exec ${pkgs.alsa-utils}/bin/amixer set Master toggle";
          "XF86AudioLowerVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 4%-";
          "XF86AudioRaiseVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 4%+";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 4%-";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 4%+";
          "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -modi drun -show drun";
          "${modifier}+Shift+x" = "exec systemctl suspend";
          "${modifier}+Shift+p" = "exec ${pkgs.flameshot}/bin/flameshot gui";
        };

        startup = [
          {
            command = "exec i3-msg workspace 1";
            always = true;
            notification = false;
          }
          {
            command = "systemctl --user restart polybar.service";
            always = true;
            notification = false;
          }
          {
            command = "picom";
            always = true;
            notification = false;
          }
          {
            command = "${pkgs.feh}/bin/feh --bg-scale ${config.theme.wallpaper}";
            always = true;
            notification = false;
          }
        ];
      };
      extraConfig = ''
        default_border pixel 0
      '';
    };
  };
}
