{
  config,
  flake,
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
      pkgs.niri-unstable
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
  imports = [ flake.inputs.niri.homeModules.niri ];

  options.home-manager.wm.niri.enable = lib.mkEnableOption "niri config" // {
    default = lib.attrByPath [ "nixos" "desktop" "wayland" "enable" ] false osCfg;
  };

  config = lib.mkIf config.home-manager.wm.niri.enable {

    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

    programs.fuzzel.enable = true;

    programs.niri.settings = {

      spawn-at-startup = [
        { command = [ "${lib.getExe pkgs.xwayland-satellite}" ]; }
        {
          command = [
            "${lib.getExe pkgs.swaybg}"
            "--image"
            "${config.shared.theme.wallpaper}"
          ];
        }
      ];

      environment = {
        DISPLAY = ":0";
        QT_QPA_PLATFORM = "wayland";
      };

      outputs."eDP-1".scale = 1.15;

      prefer-no-csd = true;
      window-rules = [
        # Godot
        {
          matches = [
            {
              app-id = "^game.*";
            }
          ];
          open-floating = true;
        }

        # General
        {
          clip-to-geometry = true;
          geometry-corner-radius = {
            top-left = 12.0;
            top-right = 12.0;
            bottom-left = 12.0;
            bottom-right = 12.0;
          };
        }
      ];

	      layout = {
	        shadow.enable = true;
	        focus-ring = {
	          width = 2;
	          active.color = config.shared.theme.nord.colors.background.primary;
	        };
	      };

      input = {
        power-key-handling.enable = false;
        keyboard = { inherit xkb; };
        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };
      };

      binds = defaultKeyBinds // {
        "Mod+Return".action.spawn = "alacritty";
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
