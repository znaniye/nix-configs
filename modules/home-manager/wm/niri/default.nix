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
  config = lib.mkIf config.home-manager.wm.niri.enable {

    programs.fuzzel.enable = true;
    services.gammastep = {
      enable = true;
      latitude = -19.9167;
      longitude = -43.9345;
      provider = "manual";
    };
    systemd.user.services = {
      niri-corne-layout = {
        Install.WantedBy = [ "niri.service" ];
        Service = {
          ExecStart = lib.getExe corneLayout;
          Restart = "on-failure";
          RestartSec = 2;
        };
        Unit = {
          After = [ "niri.service" ];
          Description = "Select niri keyboard layout from connected keyboards";
          PartOf = [ "niri.service" ];
        };
      };
    };
    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      portalPackage = null;

      settings = {
        _children = [
          {
            "spawn-at-startup"._args = [
              (lib.getExe pkgs.swaybg)
              "--image"
              "${config.shared.theme.wallpaper}"
            ];
          }
          {
            "window-rule"._children = [
              {
                match._props = {
                  "app-id" = "^game.*";
                };
              }
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
        binds = defaultKeyBinds // {
          "Mod+Return" = {
            spawn = "alacritty";
          };
        };
        environment = {
          DISPLAY = ":0";
          QT_QPA_PLATFORM = "wayland";
        };
        input = {
          keyboard = {
            xkb = {
              inherit (xkb) layout variant;
            };
          };
          touchpad = {
            "click-method" = "clickfinger";
            dwt = { };
            "natural-scroll" = { };
            tap = { };
          };
        };
        layout = {
          "focus-ring" = {
            "active-color" = config.shared.theme.nord.colors.background.primary;
            on = { };
            width = 2;
          };
          shadow = {
            on = { };
          };
        };
        output = {
          _args = [ "eDP-1" ];
          scale = 1.15;
        };
        "prefer-no-csd" = { };
      };
    };
    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  };
  options.home-manager.wm.niri.enable = lib.mkEnableOption "niri config" // {
    default = lib.attrByPath [ "nixos" "desktop" "wayland" "enable" ] false osCfg;
  };

}
