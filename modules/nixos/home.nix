{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixos.home;
in
{
  config = lib.mkIf cfg.enable {

    nixos.home.extraModules = {
      # As a rule of thumb HM == NixOS version, unless something weird happens
      home.stateVersion = lib.mkDefault config.system.stateVersion;
    };

    # Define a user account. Don't forget to set a password with ‘passwd’
    users.users.${cfg.username} = {
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
      ];
      initialPassword = "changeme";
      isNormalUser = true;
      openssh.authorizedKeys.keys = config.shared.authorizedKeys;
      shell = pkgs.zsh;
      uid = 1000;
    };
  };
  imports = [
    (flake.outputs.internal.sharedModules.helpers.mkHomeModule "nixos")
    flake.inputs.home-manager.nixosModules.home-manager
  ];
}
