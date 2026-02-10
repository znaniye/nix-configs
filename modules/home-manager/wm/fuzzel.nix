{
  osConfig,
  config,
  lib,
  ...
}:
let
  cfg = config.home-manager.wm.fuzzel;
in
{
  options.home-manager.wm.fuzzel.enable = lib.mkEnableOption "fuzzel config" // {
    default = osConfig.nixos.desktop.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.fuzzel.settings = {
      colors = {
        background = "${config.theme.nord.scheme.base00}ff";
        text = "${config.theme.nord.scheme.base04}ff";
        match = "${config.theme.nord.scheme.base0D}ff";
        selection = "${config.theme.nord.scheme.base01}ff";
        selection-text = "${config.theme.nord.scheme.base06}ff";
        selection-match = "${config.theme.nord.scheme.base0D}ff";
        border = "${config.theme.nord.scheme.base0D}ff";
      };
    };
  };
}
