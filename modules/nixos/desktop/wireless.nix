{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.nixos.desktop.wireless.enable {
    environment.systemPackages = with pkgs; [
      iw
      overskride
    ];
    hardware.bluetooth.enable = true;
    networking = {
      networkmanager = {
        enable = true;
        ensureProfiles = {
          environmentFiles = [ config.sops.secrets.wifi.path ];
          profiles = {
            home-wifi = {
              connection.id = "home-wifi";
              connection.type = "wifi";
              wifi.ssid = "$HOME_WIFI_SSID";
              wifi-security = {
                auth-alg = "open";
                key-mgmt = "wpa-psk";
                psk = "$HOME_WIFI_PASSWORD";
              };
            };
          };
        };
        wifi = {
          backend = "iwd";
          powersave = false;
        };
      };
    };
    programs.nm-applet.enable = true;
    #TODO: common module
    services = {
      resolved = lib.optionalAttrs (!config.nixos.server.pi-hole.enable) {
        dnssec = "false";
        enable = true;
      };
    };
    systemd.user.services.nm-applet = {
      serviceConfig = {
        Restart = "on-failure";
        RestartMaxDelaySec = 10;
        # Use exponential restart
        RestartSteps = 5;
      };
    };
  };
  options.nixos.desktop.wireless.enable = lib.mkEnableOption "Wi-Fi/Bluetooth config" // {
    default = config.nixos.desktop.enable;
  };

}
