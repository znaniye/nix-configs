{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.nixos.desktop.printer.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true; # IPv4
      nssmdns6 = true; # IPv6
      openFirewall = true;
    };
    services.printing = {
      drivers = [
        pkgs.epson-escpr
      ];
      enable = true;
    };
  };
  options.nixos.desktop.printer.enable = lib.mkEnableOption "printer config" // {
    default = config.nixos.desktop.enable;
  };
}
