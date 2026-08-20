{
  config,
  lib,
  osConfig,
  ...
}:
let
  cfg = config.home-manager.wm.fuzzel;
  osCfg = if osConfig == null then { } else osConfig;
in
{
  config = lib.mkIf cfg.enable {
    programs.fuzzel.settings = {
      colors = {
        background = "${config.shared.theme.nord.scheme.base00}ff";
        border = "${config.shared.theme.nord.scheme.base0D}ff";
        match = "${config.shared.theme.nord.scheme.base0D}ff";
        selection = "${config.shared.theme.nord.scheme.base01}ff";
        selection-match = "${config.shared.theme.nord.scheme.base0D}ff";
        selection-text = "${config.shared.theme.nord.scheme.base06}ff";
        text = "${config.shared.theme.nord.scheme.base04}ff";
      };
    };
  };
  options.home-manager.wm.fuzzel.enable = lib.mkEnableOption "fuzzel config" // {
    default = lib.attrByPath [ "nixos" "desktop" "wayland" "enable" ] false osCfg;
  };
}
