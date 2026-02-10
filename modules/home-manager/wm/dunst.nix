{
  osConfig,
  config,
  lib,
  ...
}:
let
  cfg = config.home-manager.wm.dunst;
in
{
  options.home-manager.wm.dunst.enable = lib.mkEnableOption "dunst cfg" // {
    default = osConfig.nixos.desktop.enable;
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = lib.mkDefault true;
      settings = {
        global = {
          frame_color = "#${config.theme.nord.scheme.base0D}";
          separator_color = "#${config.theme.nord.scheme.base03}";
          highlight = "#${config.theme.nord.scheme.base0D}";
        };

        urgency_low = {
          background = "#${config.theme.nord.scheme.base00}";
          foreground = "#${config.theme.nord.scheme.base04}";
          frame_color = "#${config.theme.nord.scheme.base0C}";
        };

        urgency_normal = {
          background = "#${config.theme.nord.scheme.base00}";
          foreground = "#${config.theme.nord.scheme.base04}";
          frame_color = "#${config.theme.nord.scheme.base0D}";
        };

        urgency_critical = {
          background = "#${config.theme.nord.scheme.base00}";
          foreground = "#${config.theme.nord.scheme.base06}";
          frame_color = "#${config.theme.nord.scheme.base08}";
        };
      };
    };
  };
}
