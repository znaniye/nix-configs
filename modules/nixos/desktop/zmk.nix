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

  options.nixos.desktop.zmk = {
    enable = lib.mkEnableOption "ZMK keyboard flashing and ZMK Studio support" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;

    environment.systemPackages = [ pkgs.zmk-studio ];

    users.users.${config.shared.meta.username}.extraGroups = [ "dialout" ];
  };
}
