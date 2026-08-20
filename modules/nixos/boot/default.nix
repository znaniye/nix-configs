{ config, lib, ... }:
{
  config = lib.mkIf config.nixos.boot.systemd.enable {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
  options.nixos.boot.systemd.enable = lib.mkEnableOption "systemd-boot config" // {
    default = config.nixos.desktop.enable;
  };
}
