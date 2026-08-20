{
  config,
  lib,
  osConfig,
  ...
}:
let
  osCfg = if osConfig == null then { } else osConfig;
in
{

  config = lib.mkIf config.home-manager.wm.waybar.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          backlight = {
            format = "{percent}% {icon}";
            format-icons = [
              " "
              " "
              " "
              " "
              " "
              " "
              " "
              " "
              " "
            ];
          };
          battery = {
            format = "{capacity}% {icon}";
            format-alt = "{time} {icon}";
            format-charging = "{capacity}% 🗲";
            format-icons = [
              " "
              " "
              " "
              " "
              " "
            ];
            format-plugged = "{capacity}%  ";
            states = {
              critical = 15;
              warning = 30;
            };
          };
          clock = {
            calendar = {
              format = {
                days = "<span color='#${config.shared.theme.nord.scheme.base04}'><b>{}</b></span>";
                months = "<span color='#${config.shared.theme.nord.scheme.base0D}'><b>{}</b></span>";
                today = "<span color='#${config.shared.theme.nord.scheme.base08}'><b><u>{}</u></b></span>";
                weekdays = "<span color='#${config.shared.theme.nord.scheme.base09}'><b>{}</b></span>";
                weeks = "<span color='#${config.shared.theme.nord.scheme.base0C}'><b>W{}</b></span>";
              };
              mode = "year";
              mode-mon-col = 3;
              on-scroll = 1;
              weeks-pos = "right";
            };
            format = "{:%H:%M}";
            format-alt = "{:%A, %B %d, %Y (%R)}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
          };
          cpu = {
            format = "{usage}%  ";
            tooltip = false;
          };
          height = 37;
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = " ";
              deactivated = " ";
            };
          };
          layer = "top";
          memory.format = "{}%  ";
          modules-center = [
            "clock"
          ];
          modules-left = [
            "niri/workspaces"
            "niri/window"
          ];
          modules-right = [
            "cpu"
            "memory"
            "pulseaudio#volume"
            "pulseaudio#mic"
            "backlight"
            #"niri/language"
            "tray"
            "battery"
          ];
          "niri/language" = {
            format = "{}";
            max-length = 18;
          };
          "niri/window" = {
            format = "{title}";
            max-length = 40;
            separate-outputs = true;
          };
          "niri/workspaces" = {
            all-outputs = true;
            disable-scroll = true;
            format = "{icon}";
            format-icons = {
              "1" = " ";
              "2" = " ";
              "3" = " ";
              "4" = " ";
              "5" = " ";
            };
            persistent-workspaces = {
              "*" = 5;
            };
          };
          position = "top";
          "pulseaudio#mic" = {
            format = "{format_source}";
            format-source = "{volume}% ";
            format-source-muted = " ";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          };
          "pulseaudio#volume" = {
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon}";
            format-bluetooth-muted = " {icon}";
            format-icons = [
              ""
              " "
              " "
            ];
            format-muted = " ";
            on-click = "pavucontrol";
          };
          spacing = 4;
          temperature = {
            critical-threshold = 95;
            format = "{temperatureC}°C {icon}";
            format-icons = [
              ""
              ""
              ""
            ];
          };
        };
      };
      style = ''
           * {
          font-family: 'Iosevka Nerd Font';
          font-size: 12px;
          font-weight: 600;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background: #${config.shared.theme.nord.scheme.base01};
          color: #${config.shared.theme.nord.scheme.base05};
        }

        #workspaces {
          background: #${config.shared.theme.nord.scheme.base02};
          margin: 5px 5px 5px 10px;
          padding: 0px 5px;
          border-radius: 16px;
          border: solid 0px #${config.shared.theme.nord.scheme.base0D};
          font-weight: bold;
          font-style: normal;
        }

        #workspaces button {
          padding: 0px 5px;
          margin: 4px 3px;
          border-radius: 16px;
          border: solid 0px #${config.shared.theme.nord.scheme.base0D};
          color: #${config.shared.theme.nord.scheme.base04};
          background: transparent;
          transition: all 0.3s ease-in-out;
        }

        #workspaces button.active {
          color: #${config.shared.theme.nord.scheme.base00};
          background: #${config.shared.theme.nord.scheme.base0D};
          border-radius: 16px;
          min-width: 40px;
        }

        #workspaces button:hover {
          color: #${config.shared.theme.nord.scheme.base0D};
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
        }

        #custom-launcher {
          color: #${config.shared.theme.nord.scheme.base0D};
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          margin-left: 10px;
          padding: 2px 17px;
          font-size: 15px;
        }

        #window {
          color: #${config.shared.theme.nord.scheme.base04};
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          padding: 2px 15px;
        }

        #clock {
          color: #${config.shared.theme.nord.scheme.base05};
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          padding: 2px 15px;
        }

        #language,
        #pulseaudio,
        #backlight,
        #network,
        #battery {
          color: #${config.shared.theme.nord.scheme.base05};
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px 2px;
          padding: 2px 12px;
        }

        #pulseaudio {
          color: #${config.shared.theme.nord.scheme.base0D};
        }

        #backlight {
          color: #${config.shared.theme.nord.scheme.base0A};
        }

        #network {
          color: #${config.shared.theme.nord.scheme.base0B};
        }

        #battery {
          color: #${config.shared.theme.nord.scheme.base0C};
        }

        #battery.charging {
          color: #${config.shared.theme.nord.scheme.base0B};
        }

        #battery.warning:not(.charging) {
          color: #${config.shared.theme.nord.scheme.base09};
        }

        #battery.critical:not(.charging) {
          color: #${config.shared.theme.nord.scheme.base08};
        }

        #tray {
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          padding: 2px 5px;
        }

        #custom-power {
          color: #${config.shared.theme.nord.scheme.base08};
          background: #${config.shared.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          margin-right: 10px;
          padding: 2px 12px;
        }
      '';
      systemd.enable = true;
    };
  };
  options.home-manager.wm.waybar.enable = lib.mkEnableOption "waybar config" // {
    default = lib.attrByPath [ "nixos" "desktop" "wayland" "enable" ] false osCfg;
  };
}
