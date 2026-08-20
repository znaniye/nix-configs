{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.nixos.desktop.xserver.enable {
    environment.systemPackages = with pkgs; [ xclip ];
    services = {
      displayManager = {
        autoLogin = {
          enable = true;
          user = config.shared.meta.username;
        };
        defaultSession = "none+i3";
      };
      redshift = {
        brightness = {
          day = "1";
          night = "0.8";
        };
        enable = true;
        latitude = "-23.5505";
        longitude = "-46.6333";
        provider = "manual";
        temperature = {
          day = 5500;
          night = 2700;
        };
      };
      xserver = {
        enable = true;
        windowManager.i3.enable = true;
        xkb = {
          layout = "br";
          variant = "abnt2";
        };
      };
    };
  };
  options.nixos.desktop.xserver.enable = lib.mkEnableOption "xserver config" // {
    default = false;
  };
}
