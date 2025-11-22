{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.home-manager.dev.python.enable = lib.mkEnableOption "Python config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.python.enable {
    home.packages = with pkgs; [
      pyright
      python3
      ruff
      uv
    ];
  };
}
