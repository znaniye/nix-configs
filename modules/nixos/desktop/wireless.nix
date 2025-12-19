{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.nixos.desktop.wireless.enable = lib.mkEnableOption "Wi-Fi/Bluetooth config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.wireless.enable {
    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          powersave = false;
          backend = "iwd";
        };

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
      };
    };

    environment.systemPackages = with pkgs; [ iw ];

    hardware.bluetooth.enable = true;

    programs.nm-applet.enable = true;

    systemd.user.services.nm-applet = {
      serviceConfig = {
        # Use exponential restart
        RestartSteps = 5;
        RestartMaxDelaySec = 10;
        Restart = "on-failure";
      };
    };

    #TODO: common module
    services = {
      blueman.enable = true;
      resolved = lib.optionalAttrs (!config.nixos.server.pi-hole.enable) {
        enable = true;
        dnssec = "false";
      };
    };
  };

}
