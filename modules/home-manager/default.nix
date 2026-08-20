{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.home-manager.enable {
    home = {
      homeDirectory = lib.mkOptionDefault (
        if pkgs.stdenv.hostPlatform.isDarwin then "/Users/znaniye" else "/home/znaniye"
      );
      username = lib.mkOptionDefault "znaniye";
    };
  };
  imports = [
    ./cli
    ./desktop
    ./dev
    ./editor
    ./sops-home-manager.nix
    ./wm
    flake.outputs.internal.sharedModules.default
  ];
  options.home-manager = {
    enable = lib.mkEnableOption "home-manager base config" // {
      default = true;
    };

    hostName = lib.mkOption {
      default = "generic";
      description = "The hostname of the machine.";
      type = lib.types.str;
    };
  };
}
