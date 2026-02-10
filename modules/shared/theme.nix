{ lib, ... }:
{

  options.theme = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./wallpaper.png;
    };

    nord = lib.mkOption {
      default = {
        scheme = {
          system = "base24";
          name = "Nord";
          author = "Arctic Ice Studio (https://www.nordtheme.com)";
          variant = "dark";

          # Base colors (backgrounds and text)
          base00 = "2e3440"; # Main background (Nord0)
          base01 = "3b4252"; # Secondary background (Nord1)
          base02 = "434c5e"; # Input fields, elevated surfaces (Nord2)
          base03 = "4c566a"; # Borders, inactive elements (Nord3)
          base04 = "d8dee9"; # Secondary text (Nord4)
          base05 = "e5e9f0"; # Primary text (Nord5)
          base06 = "eceff4"; # High emphasis text (Nord6)
          base07 = "eceff4"; # Brightest text (Nord6)

          # Semantic colors
          base08 = "bf616a"; # Red - errors, deletion (Nord11)
          base09 = "d08770"; # Orange - warnings (Nord12)
          base0A = "ebcb8b"; # Yellow - caution (Nord13)
          base0B = "a3be8c"; # Green - success (Nord14)
          base0C = "8fbcbb"; # Cyan - info (Nord7)
          base0D = "88c0d0"; # Blue - primary actions (Nord8)
          base0E = "b48ead"; # Purple - special features (Nord15)
          base0F = "bf616a"; # Alternative accent (Nord11)

          # Extended Base24 colors
          base10 = "2e3440"; # Darker background variant (Nord0)
          base11 = "2e3440"; # Darkest background (Nord0)
          base12 = "bf616a"; # Bright red (Nord11)
          base13 = "ebcb8b"; # Bright yellow (Nord13)
          base14 = "a3be8c"; # Bright green (Nord14)
          base15 = "8fbcbb"; # Bright cyan (Nord7)
          base16 = "81a1c1"; # Bright blue (Nord9)
          base17 = "b48ead"; # Bright purple (Nord15)
        };

        # Semantic aliases for easier usage
        colors = {
          background = {
            primary = "2e3440"; # base00
            secondary = "3b4252"; # base01
            tertiary = "434c5e"; # base02
            darker = "2e3440"; # base10
            darkest = "2e3440"; # base11
          };

          foreground = {
            primary = "e5e9f0"; # base05
            secondary = "d8dee9"; # base04
            emphasis = "eceff4"; # base06
            bright = "eceff4"; # base07
          };

          accent = {
            red = "bf616a"; # base08
            orange = "d08770"; # base09
            yellow = "ebcb8b"; # base0A
            green = "a3be8c"; # base0B
            cyan = "8fbcbb"; # base0C
            blue = "88c0d0"; # base0D
            purple = "b48ead"; # base0E
          };

          bright = {
            red = "bf616a"; # base12
            yellow = "ebcb8b"; # base13
            green = "a3be8c"; # base14
            cyan = "8fbcbb"; # base15
            blue = "81a1c1"; # base16
            purple = "b48ead"; # base17
          };

          border = "4c566a"; # base03
          darkRed = "bf616a"; # base0F
        };
      };
    };
  };
}
