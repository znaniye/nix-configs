{
  services.picom = {
    activeOpacity = 0.99;

    enable = true;

    backend = "glx";

    settings = {
      no-fading-openclose = true;
      invert-color-include = ["TAG_INVERT@:8c = 1"];

      blur = {
        method = "gaussian";
        size = 10;
        deviation = 5.0;
      };
    };

    fade = true;
    fadeDelta = 12;
    fadeSteps = [
      0.15
      0.15
    ];

    inactiveOpacity = 0.9;

    menuOpacity = 0.98;

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

    opacityRules = [
      "80:class_i ?= 'rofi'"
      "100:class_g ?= 'firefox'"
      "100:class_i ?= 'firefox'"
    ];
  };
}
