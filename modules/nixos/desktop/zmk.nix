{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.desktop.zmk;
in
{

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.zmk-studio ];
    services.udisks2.enable = true;
    users.users.${config.shared.meta.username}.extraGroups = [ "dialout" ];
  };
  options.nixos.desktop.zmk = {
    enable = lib.mkEnableOption "ZMK keyboard flashing and ZMK Studio support" // {
      default = false;
    };
  };
}
