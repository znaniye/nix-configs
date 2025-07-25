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
            background = "0x1d2021";
            foreground = "0xd4be98";
          };
          normal = {
            black = "0x32302f";
            red = "0xea6962";
            green = "0xa9b665";
            yellow = "0xd8a657";
            blue = "0x7daea3";
            magenta = "0xd3869b";
            cyan = "0x89b482";
            white = "0xd4be98";
          };
          bright = {
            black = "0x32302f";
            red = "0xea6962";
            green = "0xa9b665";
            yellow = "0xd8a657";
            blue = "0x7daea3";
            magenta = "0xd3869b";
            cyan = "0x89b482";
            white = "0xd4be98";
          };
        };
      };
    };
  };
}
