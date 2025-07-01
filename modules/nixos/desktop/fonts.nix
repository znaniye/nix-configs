{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.nixos.desktop.fonts.enable = lib.mkEnableOption "fonts config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.fonts.enable {
    fonts = {
      fontDir.enable = true;

      packages = with pkgs; [
        nerd-fonts.iosevka
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [ "Iosevka Nerd Font Mono" ];
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
        };
      };
    };
  };
}
