{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  defaultKeyBinds = import ./defaultKeyBinds.nix;
  osCfg = if osConfig == null then { } else osConfig;
  brIndex = 0;
  usIndex = 1;

  xkb = {
    layout = "br,us";
    variant = "abnt2,altgr-intl";
  };

  corneId = "Vendor=1d50 Product=615e";

  corneLayout = pkgs.writeShellApplication {
    name = "niri-corne-layout";
    runtimeInputs = [
      pkgs.niri
      pkgs.systemd
    ];
    text = ''
      recompute() {
        if grep -qi '${corneId}' /proc/bus/input/devices; then
          niri msg action switch-layout ${toString usIndex}
        else
          niri msg action switch-layout ${toString brIndex}
        fi
      }

      recompute

      udevadm monitor --udev --subsystem-match=input | while read -r _; do
        recompute
      done
    '';
  };
in
{
  options.home-manager.wm.niri.enable = lib.mkEnableOption "niri config" // {
    default = lib.attrByPath [ "nixos" "desktop" "wayland" "enable" ] false osCfg;
  };

  config = lib.mkIf config.home-manager.wm.niri.enable {

    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

    programs.fuzzel.enable = true;

    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      portalPackage = null;

      settings = {
        _children = [
          {
            "spawn-at-startup"._args = [ (lib.getExe pkgs.xwayland-satellite) ];
          }
          {
            "spawn-at-startup"._args = [
              (lib.getExe pkgs.swaybg)
              "--image"
              (toString config.shared.theme.wallpaper)
            ];
          }

          {
            "window-rule"._children = [
              { match._props = { "app-id" = "^game.*"; }; }
              { "open-floating" = true; }
            ];
          }

          {
            "window-rule"._children = [
              { "clip-to-geometry" = true; }
              {
                "geometry-corner-radius"._args = [
                  12.0
                  12.0
                  12.0
                  12.0
                ];
              }
            ];
          }
        ];

        environment = {
          DISPLAY = ":0";
          QT_QPA_PLATFORM = "wayland";
        };

        output = {
          _args = [ "eDP-1" ];
          scale = 1.15;
        };

        "prefer-no-csd" = { };

        layout = {
          shadow = {
            on = { };
          };
          "focus-ring" = {
            on = { };
            width = 2;
            "active-color" = config.shared.theme.nord.colors.background.primary;
          };
        };

        input = {
          keyboard = {
            xkb = {
              inherit (xkb) layout variant;
            };
          };
          touchpad = {
            tap = { };
            dwt = { };
            "natural-scroll" = { };
            "click-method" = "clickfinger";
          };
        };

        binds = defaultKeyBinds // {
          "Mod+Return" = { spawn = "alacritty"; };
        };
      };
    };

    systemd.user.services = {
      niri-corne-layout = {
        Unit = {
          Description = "Select niri keyboard layout from connected keyboards";
          PartOf = [ "niri.service" ];
          After = [ "niri.service" ];
        };
        Service = {
          ExecStart = lib.getExe corneLayout;
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "niri.service" ];
      };
    };

    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = -19.9167;
      longitude = -43.9345;
    };

  };

}
