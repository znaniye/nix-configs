{
  config,
  lib,
  ...
}:
{
  options.darwin.openssh.enable = lib.mkEnableOption "OpenSSH server config (Remote Login)";

  config = lib.mkIf config.darwin.openssh.enable {
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        PermitRootLogin no
      '';
    };
  };
}
