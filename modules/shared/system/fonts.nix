{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.shared.fonts;
in
{
  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];
  };
  options.shared.fonts.enable = lib.mkEnableOption "shared font packages";
}
