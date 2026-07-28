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
  imports = [
    (flake.outputs.internal.sharedModules.helpers.mkHomeModule "darwin")
    flake.inputs.home-manager.darwinModules.home-manager
  ];

  config = lib.mkIf cfg.enable {
    darwin.home.extraModules = {
      home.stateVersion = lib.mkDefault "24.05";
    };

    system.primaryUser = lib.mkDefault cfg.username;

    users.users.${cfg.username}.home = lib.mkDefault "/Users/${cfg.username}";
  };
}
