{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.haskell.enable = lib.mkEnableOption "haskell dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.haskell.enable {
    home.packages = with pkgs; [
      ghc
    ];
  };
}
