{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nixos.desktop.xserver.enable = lib.mkEnableOption "xserver config" // {
    default = false;
  };

  config = lib.mkIf config.nixos.desktop.xserver.enable {
    services = {
      displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = true;
          user = config.meta.username;
        };
      };

      xserver = {
        enable = true;

        xkb = {
          variant = "";
          layout = "br";
        };

        windowManager.i3.enable = true;
      };

      redshift = {
        enable = true;
        provider = "manual";
        latitude = "-23.5505";
        longitude = "-46.6333";
        temperature = {
          day = 5500;
          night = 2700;
        };
        brightness = {
          day = "1";
          night = "0.8";
        };
      };
    };

    environment.systemPackages = with pkgs; [ xclip ];
  };
}
