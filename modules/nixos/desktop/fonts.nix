{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.nixos.desktop.fonts.enable {
    fonts = {
      fontDir.enable = true;

      fontconfig = {
        defaultFonts = {
          monospace = [ "Iosevka Nerd Font Mono" ];
          sansSerif = [ "Noto Sans" ];
          serif = [ "Noto Serif" ];
        };
      };
    };
    shared.fonts.enable = true;
  };
  options.nixos.desktop.fonts.enable = lib.mkEnableOption "fonts config" // {
    default = config.nixos.desktop.enable;
  };
}
