{ config, lib, ... }:
let
  cfg = config.shared.tailscale;
in
{
  options.shared.tailscale.enable = lib.mkEnableOption "tailscale client daemon";

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}
