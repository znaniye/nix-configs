{
  config,
  flake,
  pkgs,
  ...
}:

{
  imports = [
    flake.inputs.nixos-wsl.nixosModules.wsl
  ];

  wsl = {
    enable = true;
    defaultUser = "${config.meta.username}";
    startMenuLaunchers = true;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
}
