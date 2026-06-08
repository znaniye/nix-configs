{
  config,
  lib,
  osConfig,
  ...
}:
let
  cfg = config.home-manager.wm.dunst;
  osCfg = if osConfig == null then { } else osConfig;
in
{
  options.home-manager.wm.dunst.enable = lib.mkEnableOption "dunst cfg" // {
    default = lib.attrByPath [ "nixos" "desktop" "enable" ] false osCfg;
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = lib.mkDefault true;
      settings = {
        global = {
          frame_color = "#${config.shared.theme.nord.scheme.base0D}";
          separator_color = "#${config.shared.theme.nord.scheme.base03}";
          highlight = "#${config.shared.theme.nord.scheme.base0D}";
        };

        urgency_low = {
          background = "#${config.shared.theme.nord.scheme.base00}";
          foreground = "#${config.shared.theme.nord.scheme.base04}";
          frame_color = "#${config.shared.theme.nord.scheme.base0C}";
        };

        urgency_normal = {
          background = "#${config.shared.theme.nord.scheme.base00}";
          foreground = "#${config.shared.theme.nord.scheme.base04}";
          frame_color = "#${config.shared.theme.nord.scheme.base0D}";
        };

        urgency_critical = {
          background = "#${config.shared.theme.nord.scheme.base00}";
          foreground = "#${config.shared.theme.nord.scheme.base06}";
          frame_color = "#${config.shared.theme.nord.scheme.base08}";
        };
      };
    };
  };
}
