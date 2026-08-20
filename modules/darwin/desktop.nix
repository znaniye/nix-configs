{ config, lib, ... }:
let
  cfg = config.darwin.desktop;
  hmApps = "/Users/${config.darwin.home.username}/Applications/Home Manager Apps";
in
{
  config = lib.mkIf cfg.enable {
    darwin.openssh.enable = lib.mkDefault true;
    darwin.wireguard.enable = lib.mkDefault true;
    shared.fonts.enable = lib.mkDefault true;
    shared.tailscale.enable = lib.mkDefault true;
    system.defaults.WindowManager = {
      StageManagerHideWidgets = true;
      StandardHideWidgets = true;
    };
    system.defaults.dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      persistent-apps = [
        "${hmApps}/Spotify.app"
        "${hmApps}/Vesktop.app"
        "${hmApps}/Telegram.app"
        "${hmApps}/Alacritty.app"
      ];
      show-recents = false;
    };
  };
  options.darwin.desktop.enable = lib.mkEnableOption "darwin desktop config";
}
