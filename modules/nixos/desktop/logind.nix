{ config, lib, ... }:
{
  options.nixos.desktop.logind.ignoreLidSwitchExternalPower.enable =
    lib.mkEnableOption "ignore lid switch on external power"
    // {
      default = config.nixos.desktop.enable;
    };

  config = lib.mkIf config.nixos.desktop.logind.ignoreLidSwitchExternalPower.enable {
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  };
}
