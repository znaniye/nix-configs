{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.zig.enable = lib.mkEnableOption "zig config" // {
    default = config.home-manager.dev.enable;
  };

  config = lib.mkIf config.home-manager.dev.zig.enable {
    home = {
      packages = with pkgs; [
        zigpkgs."0.15.1"
        zls
      ];
    };
  };
}
