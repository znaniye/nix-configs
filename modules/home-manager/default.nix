{
  config,
  flake,
  lib,
  ...
}:
{
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
      description = "The hostname of the machine.";
      type = lib.types.str;
      default = "generic";
    };
  };

  config = lib.mkIf config.home-manager.enable {
    home = {
      username = lib.mkOptionDefault "znaniye";
      homeDirectory = lib.mkOptionDefault "/home/znaniye";
    };
  };
}
