{
  config,
  lib,
  ...
}:
{
  options.home-manager.desktop.alacritty.enable = lib.mkEnableOption "alacritty config " // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.alacritty.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        window = {
          title = "Terminal";

          opacity = 0.8;

          padding = {
            x = 5;
            y = 5;
          };
          dimensions = {
            lines = 75;
            columns = 100;
          };
        };

        font = {
          normal = {
            family = "Iosevka Nerd Font";
            style = "Medium";
          };
          size = 14;
        };

        colors = {
          primary = {
            background = "0x${config.theme.nord.scheme.base00}";
            foreground = "0x${config.theme.nord.scheme.base04}";
          };
          normal = {
            black = "0x${config.theme.nord.scheme.base01}";
            red = "0x${config.theme.nord.scheme.base08}";
            green = "0x${config.theme.nord.scheme.base0B}";
            yellow = "0x${config.theme.nord.scheme.base0A}";
            blue = "0x${config.theme.nord.scheme.base16}";
            magenta = "0x${config.theme.nord.scheme.base0E}";
            cyan = "0x${config.theme.nord.scheme.base0D}";
            white = "0x${config.theme.nord.scheme.base05}";
          };
          bright = {
            black = "0x${config.theme.nord.scheme.base03}";
            red = "0x${config.theme.nord.scheme.base08}";
            green = "0x${config.theme.nord.scheme.base0B}";
            yellow = "0x${config.theme.nord.scheme.base0A}";
            blue = "0x${config.theme.nord.scheme.base16}";
            magenta = "0x${config.theme.nord.scheme.base0E}";
            cyan = "0x${config.theme.nord.scheme.base0C}";
            white = "0x${config.theme.nord.scheme.base06}";
          };
        };
      };
    };
  };
}
