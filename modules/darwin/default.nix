{
  config,
  flake,
  lib,
  ...
}:
{
  imports = [
    ../shared/meta.nix
    ../shared/theme.nix
    ./home.nix
    ./nix
    ./openssh.nix
    ./wireguard.nix
    flake.outputs.internal.sharedModules.system
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  programs.zsh.enable = lib.mkDefault true;

  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.0;
    show-recents = false;
  };

  system.defaults.CustomUserPreferences."com.apple.WindowManager" = {
    StandardHideWidgets = true;
    StageManagerHideWidgets = true;
  };

  system.activationScripts.postActivation.text = ''
    osascript -e 'tell application "System Events" to tell every desktop to set picture to "${config.shared.theme.wallpaper}"'
  '';

  system.stateVersion = lib.mkDefault 5;
}
