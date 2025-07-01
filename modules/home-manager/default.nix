{
  config,
  flake,
  lib,
  ...
}:
{
  imports = [
    flake.outputs.internal.sharedModules.default
    ./cli
    ./desktop
    #./editor
    ./wm
  ];

  home = {
    username = lib.mkOptionDefault config.meta.username;
    homeDirectory = lib.mkOptionDefault "/home/${config.meta.username}";
    stateVersion = lib.mkOptionDefault "25.05";
  };
}
