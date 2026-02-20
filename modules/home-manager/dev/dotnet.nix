{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.dotnet.enable = lib.mkEnableOption "dotnet stuff" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.dotnet.enable {
    home.packages = with pkgs; [
      dotnet-sdk_10
      csharp-ls
      fsautocomplete
      fantomas
    ];
  };
}
