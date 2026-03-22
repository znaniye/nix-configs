{
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
    ./wm
    flake.outputs.internal.sharedModules.default
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
