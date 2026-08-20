{
  config,
  lib,
  pkgs,
  ...
}:
let
  mf = "#383838";
  bg = "#00000000";
  fg = "#fbf1c7";

  # blue
  primary = "#076678";

  # Dark
  secondary = "#282828";

  # green
  tertiary = "#98971a";

  # white
  quaternary = "#fbf1c7";

  # middle gray
  quinternary = "#282828";

  # Red
  urgency = "#9d0006";
in
{

  config = lib.mkIf config.home-manager.wm.polybar.enable {
    services.polybar = {
      config = {
        "bar/bottom" = {
          background = bg;
          #monitor = "HDMI-1";
          bottom = true;
          fixed-center = true;
          font-0 = "Iosevka Nerd Font:style=Medium:size=12;3";
          foreground = fg;
          height = 19;
          locale = "pt_BR.UTF-8";
          #modules-left = "powermenu";
          modules-right = "ddrS cpu dulS ddrT memory dulT ddrP battery";
          offset-x = "1%";
          padding = 0;
          radius-top = 0;
          tray-background = primary;
          tray-detached = false;
          tray-maxsize = 15;
          tray-offset-x = -19;
          tray-offset-y = 0;
          tray-padding = 5;
          tray-position = "left";
          tray-scale = 1;
          width = "100%";
        };
        #====================BARS====================#
        "bar/top" = {
          background = bg;
          #monitor = "HDMI-1";
          bottom = false;
          fixed-center = true;
          font-0 = "Iosevka Nerd Font:style=Medium:size=12;3";
          foreground = fg;
          height = 19;
          locale = "pt_BR.UTF-8";
          modules-center = "title";
          modules-left = "distro-icon dulS ddrT i3 dulT";
          modules-right = "network date";
          offset-x = "1%";
          radius = 0;
          scroll-down = "i3wm-wsprev";
          scroll-up = "i3wm-wsnext";
          width = "100%";
        };
        "global/wm" = {
          margin-bottom = 0;
          margin-top = 0;
        };
        "module/battery" = {
          adapter = "AC0";
          animation-charging-0 = " ";
          animation-charging-1 = " ";
          animation-charging-2 = " ";
          animation-charging-3 = " ";
          animation-charging-4 = " ";
          animation-charging-framerate = 500;
          battery = "BAT0"; # TODO: Better way to fill this
          format-charging = " <animation-charging> <label-charging>";
          format-charging-background = primary;
          format-charging-foreground = secondary;
          format-charging-padding = 1;
          format-discharging = "<ramp-capacity> <label-discharging>";
          format-discharging-background = primary;
          format-discharging-foreground = secondary;
          format-discharging-padding = 1;
          format-full-background = primary;
          format-full-foreground = secondary;
          format-full-padding = 1;
          full-at = 101; # to disable it
          label-charging = "%percentage%% +%consumption%W";
          label-discharging = "%percentage%% -%consumption%W";
          label-full = "  100%";
          poll-interval = 2;
          ramp-capacity-0 = " ";
          ramp-capacity-0-foreground = urgency;
          ramp-capacity-1 = " ";
          ramp-capacity-1-foreground = urgency;
          ramp-capacity-2 = " ";
          ramp-capacity-3 = " ";
          ramp-capacity-4 = " ";
          type = "internal/battery";
        };
        "module/cpu" = {
          format = " <label>";
          format-background = secondary;
          format-foreground = quaternary;
          format-padding = 1;
          interval = "0.5";
          label = "CPU %percentage%%";
          type = "internal/cpu";
        };
        "module/daPT" = {
          content = "";
          content-background = primary;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/daSP" = {
          content = "";
          content-background = secondary;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/daST" = {
          content = "";
          content-background = secondary;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/daTP" = {
          content = "";
          content-background = tertiary;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/daTS" = {
          content = "";
          content-background = secondary;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/date" = {
          format = "<label>";
          format-foreground = fg;
          format-padding = 4;
          interval = "1.0";
          label = "%time%";
          time = "%H:%M:%S";
          time-alt = "%Y-%m-%d%";
          type = "internal/date";
        };
        "module/ddlP" = {
          content = "";
          content-background = bg;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/ddlS" = {
          content = "";
          content-background = bg;
          content-foreground = secondary;
          type = "custom/text";
        };
        "module/ddlT" = {
          content = "";
          content-background = bg;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/ddrP" = {
          content = "";
          content-background = bg;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/ddrS" = {
          content = "";
          content-background = bg;
          content-foreground = secondary;
          type = "custom/text";
        };
        "module/ddrT" = {
          content = "";
          content-background = bg;
          content-foreground = tertiary;
          type = "custom/text";
        };
        #--------------------MODULES--------------------"
        "module/distro-icon" = {
          exec = "${pkgs.coreutils}/bin/uname -r | ${pkgs.coreutils}/bin/cut -d- -f1";
          format = " ";
          format-background = secondary;
          format-foreground = quaternary;
          format-padding = 1;
          interval = 999999999;
          type = "custom/script";
        };
        #"module/wireless-network" = {
        #  type = "internal/network";
        #  interval = "wlp2s0";
        #};
        #--------------------SOLID TRANSITIONS--------------------#
        "module/dsPT" = {
          content = "";
          content-background = primary;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/dsST" = {
          content = "";
          content-background = secondary;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/dsTS" = {
          content = "";
          content-background = tertiary;
          content-foreground = secondary;
          type = "custom/text";
        };
        "module/dulP" = {
          content = "";
          content-background = bg;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/dulS" = {
          content = "";
          content-background = bg;
          content-foreground = secondary;
          type = "custom/text";
        };
        #--------------------GAPS TRANSITIONS--------------------#
        "module/dulT" = {
          content = "";
          content-background = bg;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/durP" = {
          content = "";
          content-background = bg;
          content-foreground = primary;
          type = "custom/text";
        };
        "module/durS" = {
          content = "";
          content-background = bg;
          content-foreground = secondary;
          type = "custom/text";
        };
        "module/durT" = {
          content = "";
          content-background = bg;
          content-foreground = tertiary;
          type = "custom/text";
        };
        "module/i3" = {
          format = "<label-state> <label-mode>";
          format-background = tertiary;
          label-focused = "%index% %icon%";
          label-focused-font = 2;
          label-focused-foreground = secondary;
          label-focused-padding = 1;
          label-mode = "%mode%";
          label-mode-padding = 1;
          label-separator = "";
          label-unfocused = "%icon%";
          label-unfocused-foreground = quinternary;
          label-unfocused-padding = 1;
          label-urgent = "%index%";
          label-urgent-foreground = urgency;
          label-urgent-padding = 1;
          label-visible = "%icon%";
          label-visible-padding = 1;
          pin-workspaces = false;
          strip-wsnumbers = true;
          type = "internal/i3";
          ws-icon-0 = "1;󰈹 ";
          ws-icon-1 = "2; ";
          ws-icon-2 = "3; ";
          ws-icon-3 = "4;󰙯 ";
          ws-icon-4 = "5;󱄅 ";
          ws-icon-5 = "6; ";
          ws-icon-6 = "7; ";
          ws-icon-7 = "8; ";
        };
        "module/memory" = {
          format = " <label>";
          format-background = tertiary;
          format-foreground = secondary;
          format-padding = 1;
          interval = 3;
          label = "RAM %percentage_used%%";
          type = "internal/memory";
        };
        "module/network" = {
          accumulate-stats = true;
          format-connected = "<label-connected>";
          format-connected-background = mf;
          format-connected-margin = 0;
          format-connected-overline = bg;
          format-connected-padding = 2;
          format-connected-underline = bg;
          format-disconnected = "<label-disconnected>";
          format-disconnected-background = mf;
          format-disconnected-margin = 0;
          format-disconnected-overline = bg;
          format-disconnected-padding = 2;
          format-disconnected-underline = bg;
          interface = "wlan0";
          interval = "1.0";
          label-connected = "D %downspeed:2% | U %upspeed:2%";
          label-disconnected = "DISCONNECTED";
          type = "internal/network";
          unknown-as-up = true;
        };
        "module/temperature" = {
          format = "<label>";
          format-background = mf;
          format-margin = 0;
          format-overline = bg;
          format-padding = 2;
          format-underline = bg;
          format-warn = "<label-warn>";
          format-warn-background = mf;
          format-warn-margin = 0;
          format-warn-overline = bg;
          format-warn-padding = 2;
          format-warn-underline = bg;
          interval = "0.5";
          label = "TEMP %temperature-c%";
          label-warn = "TEMP %temperature-c%";
          label-warn-foreground = "#f00";
          thermal-zone = 0; # TODO: Find a better way to fill that
          type = "internal/temperature";
          units = true;
          warn-temperature = 60;
        };
        "module/title" = {
          format = "<label>";
          format-foreground = quaternary;
          label = "%title%";
          label-maxlen = 70;
          type = "internal/xwindow";
        };
        "settings" = {
          compositing-background = "source";
          compositing-border = "over";
          compositing-foreground = "over";
          compositing-overline = "over";
          comppositing-underline = "over";
          pseudo-transparency = "false";
          screenchange-reload = true;
          throttle-input-for = 30;
          throttle-output = 5;
          throttle-output-for = 10;
        };
      };
      enable = true;
      package = pkgs.polybarFull;
      script = "polybar -q -r top & polybar -q -r bottom &";
    };
  };
  options.home-manager.wm.polybar.enable = lib.mkEnableOption "polybar config" // {
    default = config.home-manager.wm.i3.enable;
  };

}
