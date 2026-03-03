{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
#let
#  cfg = config.home-manager.editor;
#in
let
  osCfg = if osConfig == null then { } else osConfig;
in
{

  imports = [
    ./nvim
    ./emacs
  ];

  options.home-manager.editor.enable = lib.mkEnableOption "editor config" // {
    default = lib.attrByPath [ "nixos" "desktop" "enable" ] false osCfg;
  };

  #config = lib.mkIf cfg.enable {
  #  home.sessionVariables.EDITOR = "nvim";
  #};

}
