{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.lua.enable = lib.mkEnableOption "haskell dev" // {
    default = config.home-manager.dev.enable;
  };

  config = lib.mkIf config.home-manager.dev.lua.enable {
    home.packages = with pkgs; [
      ghc
    ];
  };
}
