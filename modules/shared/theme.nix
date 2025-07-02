{ lib, ... }:
{

  options.theme = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./gruvbox-dark.png;
    };
  };
}
