{ config, lib, ... }:
{
  options.nixos.desktop.tlp = {
    enable = lib.mkEnableOption "TLP config" // {
      default = config.nixos.desktop.enable;
    };
  };

  config = lib.mkIf config.nixos.desktop.tlp.enable {
    # This will set CPU_SCALING_GOVERNOR_ON_{AC,BAT} options in TLP
    # 1200 is more priority than mkOptionDefault, less than mkDefault
    powerManagement.cpuFreqGovernor = lib.mkOverride 1200 "ondemand";

    # Reduce power consumption
    services.tlp = {
      enable = true;
      # https://linrunner.de/tlp/support/optimizing.html
      settings = {
        # Enable the platform profile low-power
        PLATFORM_PROFILE_ON_BAT = lib.mkDefault "balanced";
        # Enable the platform profile performance
        PLATFORM_PROFILE_ON_AC = lib.mkDefault "performance";
        # Enable runtime power management
        RUNTIME_PM_ON_AC = lib.mkDefault "auto";
      };
    };
  };
}
