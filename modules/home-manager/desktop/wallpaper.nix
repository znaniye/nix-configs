{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.desktop.wallpaper;
in
{
  options.home-manager.desktop.wallpaper = {
    enable = lib.mkEnableOption "set the desktop wallpaper with desktoppr" // {
      default = config.home-manager.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      programs.desktoppr = {
        enable = true;
        settings.picture = builtins.toString config.shared.theme.wallpaper;
      };
    }
  );
}
