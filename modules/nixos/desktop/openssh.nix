{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.desktop.openssh;
in
{
  options.nixos.desktop.openssh.enable = lib.mkEnableOption "desktop OpenSSH config" // {
    default = true;
  };

  config = lib.mkIf (config.nixos.desktop.enable && cfg.enable) {
    services.openssh = {
      enable = lib.mkDefault true;
      settings.Macs = lib.mkDefault [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "hmac-sha2-512"
        "hmac-sha2-256"
      ];
      extraConfig = lib.mkAfter ''
        HostKeyAlgorithms +ssh-rsa
        PubkeyAcceptedAlgorithms +ssh-rsa
      '';
    };
  };
}
