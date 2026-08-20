{ config, lib, ... }:
let
  cfg = config.shared.tailscale;
in
{
  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
  };
  options.shared.tailscale.enable = lib.mkEnableOption "tailscale client daemon";
}
