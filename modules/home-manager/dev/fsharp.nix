{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.fsharp.enable = lib.mkEnableOption "fsharp dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.fsharp.enable {
    home.packages = with pkgs; [
      fsautocomplete
      fantomas
    ];
  };
}
