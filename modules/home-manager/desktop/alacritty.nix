{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.home-manager.desktop.alacritty.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        colors = {
          bright = {
            black = "0x${config.shared.theme.nord.scheme.base03}";
            blue = "0x${config.shared.theme.nord.scheme.base16}";
            cyan = "0x${config.shared.theme.nord.scheme.base0C}";
            green = "0x${config.shared.theme.nord.scheme.base0B}";
            magenta = "0x${config.shared.theme.nord.scheme.base0E}";
            red = "0x${config.shared.theme.nord.scheme.base08}";
            white = "0x${config.shared.theme.nord.scheme.base06}";
            yellow = "0x${config.shared.theme.nord.scheme.base0A}";
          };
          normal = {
            black = "0x${config.shared.theme.nord.scheme.base01}";
            blue = "0x${config.shared.theme.nord.scheme.base16}";
            cyan = "0x${config.shared.theme.nord.scheme.base0D}";
            green = "0x${config.shared.theme.nord.scheme.base0B}";
            magenta = "0x${config.shared.theme.nord.scheme.base0E}";
            red = "0x${config.shared.theme.nord.scheme.base08}";
            white = "0x${config.shared.theme.nord.scheme.base05}";
            yellow = "0x${config.shared.theme.nord.scheme.base0A}";
          };
          primary = {
            background = "0x${config.shared.theme.nord.scheme.base00}";
            foreground = "0x${config.shared.theme.nord.scheme.base04}";
          };
        };
        font = {
          normal = {
            family = "Iosevka Nerd Font Mono";
            style = "Medium";
          };
          size = 14;
        };
        window = {
          dimensions = {
            columns = 100;
            lines = 75;
          };
          opacity = 0.92;
          padding = {
            x = 5;
            y = 5;
          };
          title = "Terminal";
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          option_as_alt = "Both";
        };
      };
    };
  };
  options.home-manager.desktop.alacritty.enable = lib.mkEnableOption "alacritty config " // {
    default = config.home-manager.desktop.enable;
  };
}
