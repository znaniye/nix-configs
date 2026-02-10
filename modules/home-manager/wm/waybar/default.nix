{
  config,
  lib,
  osConfig,
  ...
}:
{

  options.home-manager.wm.waybar.enable = lib.mkEnableOption "waybar config" // {
    default = osConfig.nixos.desktop.wayland.enable or false;
  };

  config = lib.mkIf config.home-manager.wm.waybar.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 37;
          spacing = 4;

          modules-left = [
            "niri/workspaces"
            "niri/window"
          ];
          modules-center = [
            "clock"
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

          "niri/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
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

          "niri/window" = {
            format = "{title}";
            max-length = 40;
            separate-outputs = true;
          };

          "niri/language" = {
            format = "{}";
            max-length = 18;
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = " ";
              deactivated = " ";
            };
          };

          cpu = {
            format = "{usage}%  ";
            tooltip = false;
          };

          memory.format = "{}%  ";

          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%A, %B %d, %Y (%R)}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#${config.theme.nord.scheme.base0D}'><b>{}</b></span>";
                days = "<span color='#${config.theme.nord.scheme.base04}'><b>{}</b></span>";
                weeks = "<span color='#${config.theme.nord.scheme.base0C}'><b>W{}</b></span>";
                weekdays = "<span color='#${config.theme.nord.scheme.base09}'><b>{}</b></span>";
                today = "<span color='#${config.theme.nord.scheme.base08}'><b><u>{}</u></b></span>";
              };
            };
          };

          temperature = {
            critical-threshold = 95;
            format = "{temperatureC}°C {icon}";
            format-icons = [
              ""
              ""
              ""
            ];
          };

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
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% 🗲";
            format-plugged = "{capacity}%  ";
            format-alt = "{time} {icon}";
            format-icons = [
              " "
              " "
              " "
              " "
              " "
            ];
          };

          "pulseaudio#volume" = {
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon}";
            format-bluetooth-muted = " {icon}";
            format-muted = " ";
            format-icons = [
              ""
              " "
              " "
            ];
            on-click = "pavucontrol";
          };

          "pulseaudio#mic" = {
            format = "{format_source}";
            format-source = "{volume}% ";
            format-source-muted = " ";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
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
          background: #${config.theme.nord.scheme.base01};
          color: #${config.theme.nord.scheme.base05};
        }

        #workspaces {
          background: #${config.theme.nord.scheme.base02};
          margin: 5px 5px 5px 10px;
          padding: 0px 5px;
          border-radius: 16px;
          border: solid 0px #${config.theme.nord.scheme.base0D};
          font-weight: bold;
          font-style: normal;
        }

        #workspaces button {
          padding: 0px 5px;
          margin: 4px 3px;
          border-radius: 16px;
          border: solid 0px #${config.theme.nord.scheme.base0D};
          color: #${config.theme.nord.scheme.base04};
          background: transparent;
          transition: all 0.3s ease-in-out;
        }

        #workspaces button.active {
          color: #${config.theme.nord.scheme.base00};
          background: #${config.theme.nord.scheme.base0D};
          border-radius: 16px;
          min-width: 40px;
        }

        #workspaces button:hover {
          color: #${config.theme.nord.scheme.base0D};
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
        }

        #custom-launcher {
          color: #${config.theme.nord.scheme.base0D};
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          margin-left: 10px;
          padding: 2px 17px;
          font-size: 15px;
        }

        #window {
          color: #${config.theme.nord.scheme.base04};
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          padding: 2px 15px;
        }

        #clock {
          color: #${config.theme.nord.scheme.base05};
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          padding: 2px 15px;
        }

        #language,
        #pulseaudio,
        #backlight,
        #network,
        #battery {
          color: #${config.theme.nord.scheme.base05};
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px 2px;
          padding: 2px 12px;
        }

        #pulseaudio {
          color: #${config.theme.nord.scheme.base0D};
        }

        #backlight {
          color: #${config.theme.nord.scheme.base0A};
        }

        #network {
          color: #${config.theme.nord.scheme.base0B};
        }

        #battery {
          color: #${config.theme.nord.scheme.base0C};
        }

        #battery.charging {
          color: #${config.theme.nord.scheme.base0B};
        }

        #battery.warning:not(.charging) {
          color: #${config.theme.nord.scheme.base09};
        }

        #battery.critical:not(.charging) {
          color: #${config.theme.nord.scheme.base08};
        }

        #tray {
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          padding: 2px 5px;
        }

        #custom-power {
          color: #${config.theme.nord.scheme.base08};
          background: #${config.theme.nord.scheme.base02};
          border-radius: 16px;
          margin: 5px;
          margin-right: 10px;
          padding: 2px 12px;
        }
      '';
    };
  };
}
