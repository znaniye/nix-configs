{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.home-manager.wm.picom.enable {
    services.picom = {
      activeOpacity = 0.99;
      backend = "glx";
      enable = true;
      fade = true;
      fadeDelta = 12;
      fadeSteps = [
        0.15
        0.15
      ];
      inactiveOpacity = 0.9;
      menuOpacity = 0.98;
      opacityRules = [
        "80:class_i ?= 'rofi'"
        "100:class_g ?= 'firefox'"
        "100:class_i ?= 'firefox'"
      ];
      settings = {
        blur = {
          deviation = 5.0;
          method = "gaussian";
          size = 10;
        };
        invert-color-include = [ "TAG_INVERT@:8c = 1" ];
        no-fading-openclose = true;
      };
      shadow = true;
      shadowExclude = [
        "n:e:Notification"
        "name = 'cpt_frame_xcb_window'"
        "class_g ?= 'zoom'"
      ];
      shadowOffsets = [
        (-15)
        (-15)
      ];
      shadowOpacity = 0.7;
    };
  };
  options.home-manager.wm.picom.enable = lib.mkEnableOption "picom config" // {
    default = config.home-manager.wm.i3.enable;
  };
}
