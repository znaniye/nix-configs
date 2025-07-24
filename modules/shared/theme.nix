{ lib, ... }:
{

  options.theme = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./wallpaper.png;
    };

    gruvbox = lib.mkOption {
      default = {
        scheme = {
          system = "base24";
          name = "Gruvbox Dark";
          author = "Tinted Theming (https://github.com/tinted-theming), morhetz (https://github.com/morhetz/gruvbox)";
          variant = "dark";

          # Base colors (backgrounds and text)
          base00 = "282828"; # Main background
          base01 = "3c3836"; # Secondary background
          base02 = "504945"; # Input fields, elevated surfaces
          base03 = "665c54"; # Borders, inactive elements
          base04 = "928374"; # Secondary text
          base05 = "ebdbb2"; # Primary text
          base06 = "fbf1c7"; # High emphasis text
          base07 = "f9f5d7"; # Brightest text

          # Semantic colors
          base08 = "cc241d"; # Red - errors, deletion
          base09 = "d65d0e"; # Orange - warnings
          base0A = "d79921"; # Yellow - caution
          base0B = "98971a"; # Green - success
          base0C = "689d6a"; # Cyan - info
          base0D = "458588"; # Blue - primary actions
          base0E = "b16286"; # Purple - special features
          base0F = "9d0006"; # Dark red - alternative

          # Extended Base24 colors
          base10 = "2a2520"; # Darker background variant
          base11 = "1d1d1d"; # Darkest background
          base12 = "fb4934"; # Bright red
          base13 = "fabd2f"; # Bright yellow
          base14 = "b8bb26"; # Bright green
          base15 = "8ec07c"; # Bright cyan
          base16 = "83a598"; # Bright blue
          base17 = "d3869b"; # Bright purple
        };

        # Semantic aliases for easier usage
        colors = {
          background = {
            primary = "282828"; # base00
            secondary = "3c3836"; # base01
            tertiary = "504945"; # base02
            darker = "2a2520"; # base10
            darkest = "1d1d1d"; # base11
          };

          foreground = {
            primary = "ebdbb2"; # base05
            secondary = "928374"; # base04
            emphasis = "fbf1c7"; # base06
            bright = "f9f5d7"; # base07
          };

          accent = {
            red = "cc241d"; # base08
            orange = "d65d0e"; # base09
            yellow = "d79921"; # base0A
            green = "98971a"; # base0B
            cyan = "689d6a"; # base0C
            blue = "458588"; # base0D
            purple = "b16286"; # base0E
          };

          bright = {
            red = "fb4934"; # base12
            yellow = "fabd2f"; # base13
            green = "b8bb26"; # base14
            cyan = "8ec07c"; # base15
            blue = "83a598"; # base16
            purple = "d3869b"; # base17
          };

          border = "665c54"; # base03
          darkRed = "9d0006"; # base0F
        };
      };
    };
  };
}
