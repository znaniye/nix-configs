{
  config,
  flake,
  lib,
  ...
}:

let
  cfg = config.darwin.home;
in
{
  config = lib.mkIf cfg.enable {
    darwin.home.extraModules = {
      home.stateVersion = lib.mkDefault "24.05";
      targets.darwin.copyApps.enable = true;
      targets.darwin.linkApps.enable = false;
    };

    system.primaryUser = lib.mkDefault cfg.username;

    users.users.${cfg.username}.home = lib.mkDefault "/Users/${cfg.username}";
  };
  imports = [
    (flake.outputs.internal.sharedModules.helpers.mkHomeModule "darwin")
    flake.inputs.home-manager.darwinModules.home-manager
  ];
}
