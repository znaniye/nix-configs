{ config, lib, ... }:
{
  options.nixos.boot.systemd.enable = lib.mkEnableOption "systemd-boot config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.boot.systemd.enable {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
