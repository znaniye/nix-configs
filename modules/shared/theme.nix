{ lib, ... }:
{

  options.shared.theme = {
    nord = lib.mkOption {
      default = {
        # Semantic aliases for easier usage
        colors = {
          accent = {
            blue = "88c0d0"; # base0D
            cyan = "8fbcbb"; # base0C
            green = "a3be8c"; # base0B
            orange = "d08770"; # base09
            purple = "b48ead"; # base0E
            red = "bf616a"; # base08
            yellow = "ebcb8b"; # base0A
          };
          background = {
            darker = "2e3440"; # base10
            darkest = "2e3440"; # base11
            primary = "2e3440"; # base00
            secondary = "3b4252"; # base01
            tertiary = "434c5e"; # base02
          };
          border = "4c566a"; # base03
          bright = {
            blue = "81a1c1"; # base16
            cyan = "8fbcbb"; # base15
            green = "a3be8c"; # base14
            purple = "b48ead"; # base17
            red = "bf616a"; # base12
            yellow = "ebcb8b"; # base13
          };
          darkRed = "bf616a"; # base0F
          foreground = {
            bright = "eceff4"; # base07
            emphasis = "eceff4"; # base06
            primary = "e5e9f0"; # base05
            secondary = "d8dee9"; # base04
          };
        };
        scheme = {
          author = "Arctic Ice Studio (https://www.nordtheme.com)";
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
          name = "Nord";
          system = "base24";
          variant = "dark";
        };
      };
    };
    wallpaper = lib.mkOption {
      default = ./wallpaper.png;
      type = lib.types.path;
    };
  };
}
