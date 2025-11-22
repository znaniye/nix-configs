{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.zig.enable = lib.mkEnableOption "zig config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.zig.enable {
    home = {
      packages = with pkgs; [
        zig
        zls
      ];
    };
  };
}
