{
  config,
  flake,
  lib,
  ...
}:
{
  imports = [
    ../shared/meta.nix
    ../shared/authorized-keys.nix
    ../shared/theme.nix
    ./desktop.nix
    ./home.nix
    ./nix
    ./openssh.nix
    ./syncthing.nix
    ./wireguard.nix
    flake.outputs.internal.sharedModules.system
  ];
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";
  programs.zsh.enable = lib.mkDefault true;
  system.stateVersion = lib.mkDefault 5;
  users.users.${config.shared.meta.username}.openssh.authorizedKeys.keys =
    config.shared.authorizedKeys;
}
