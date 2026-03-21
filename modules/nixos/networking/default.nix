{ config, lib, ... }:
let
  cfg = config.nixos.networking;
in
{
  options.nixos.networking = {
    enable = lib.mkEnableOption "networking config" // {
      default = true;
    };

    firewall.enable = lib.mkEnableOption "firewall config" // {
      default = !config.nixos.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = cfg.firewall.enable;
  };
}
