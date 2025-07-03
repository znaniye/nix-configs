{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixos.desktop.printer.enable = lib.mkEnableOption "printer config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.printer.enable {
    services.printing = {
      enable = true;
      drivers = [
        pkgs.epson-escpr
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true; # IPv4
      nssmdns6 = true; # IPv6
      openFirewall = true;
    };
  };
}
