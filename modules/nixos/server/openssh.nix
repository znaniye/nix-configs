{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.server.openssh;
in
{
  options.nixos.server.openssh.enable = lib.mkEnableOption "server OpenSSH config" // {
    default = true;
  };

  config = lib.mkIf (config.nixos.server.enable && cfg.enable) {
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = lib.mkDefault (if config.nixos.desktop.enable then "no" else "yes");
    };
  };
}
