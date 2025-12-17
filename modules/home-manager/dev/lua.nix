{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.lua.enable = lib.mkEnableOption "Lua config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.lua.enable {
    home.packages = with pkgs; [
      lua
      lua-language-server
      love
    ];
  };
}
