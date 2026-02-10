{
  config,
  flake,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  defaultKeyBinds = import ./defaultKeyBinds.nix;
  xkb =
    if osConfig.networking.hostName != "felix" then
      {
        layout = "us";
        variant = "altgr-intl";
      }
    else
      {
        layout = "br";
      };
in
{
  imports = [ flake.inputs.niri.homeModules.niri ];

  options.home-manager.wm.niri.enable = lib.mkEnableOption "niri config" // {
    default = osConfig.nixos.desktop.wayland.enable or false;
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
            "${config.theme.wallpaper}"
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
	          active.color = config.theme.nord.colors.background.primary;
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

    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = -19.9167;
      longitude = -43.9345;
    };

  };

}
