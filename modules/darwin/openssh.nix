{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.darwin.openssh.enable {
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        PermitRootLogin no
      '';
    };
  };
  options.darwin.openssh.enable = lib.mkEnableOption "OpenSSH server config (Remote Login)";
}
