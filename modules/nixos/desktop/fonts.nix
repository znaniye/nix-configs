{
  config,
  lib,
  ...
}:

{
  options.nixos.desktop.fonts.enable = lib.mkEnableOption "fonts config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.fonts.enable {
    shared.fonts.enable = true;

    fonts = {
      fontDir.enable = true;

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
