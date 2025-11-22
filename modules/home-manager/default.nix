{
  flake,
  lib,
  ...
}:
{
  imports = [
    flake.outputs.internal.sharedModules.default
    ./cli
    ./desktop
    ./dev
    ./editor
    ./wm
  ];

  options.home-manager = {
    hostName = lib.mkOption {
      description = "The hostname of the machine.";
      type = lib.types.str;
      default = "generic";
    };
  };

  config = {
    home = {
      username = lib.mkOptionDefault "znaniye";
      homeDirectory = lib.mkOptionDefault "/home/znaniye";
    };
  };
}
