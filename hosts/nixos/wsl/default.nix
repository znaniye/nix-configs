{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
  ];

  wsl = {
    enable = true;
    defaultUser = "${config.meta.username}";
    startMenuLaunchers = true;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "24.05";
}
