{ config, lib, ... }:
let
  cfg = config.darwin.desktop;
in
{
  options.darwin.desktop.enable = lib.mkEnableOption "darwin desktop config";

  config = lib.mkIf cfg.enable {
    shared.tailscale.enable = lib.mkDefault true;
    shared.fonts.enable = lib.mkDefault true;

    darwin.wireguard.enable = lib.mkDefault true;
    darwin.openssh.enable = lib.mkDefault true;

    system.defaults.dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      show-recents = false;
    };

    system.defaults.WindowManager = {
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
    };
  };
}
