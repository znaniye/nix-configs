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
{

  imports = [
    ./nvim
    ./emacs
  ];

  options.home-manager.editor.enable = lib.mkEnableOption "editor config" // {
    default = osConfig.nixos.desktop.enable or false;
  };

  #config = lib.mkIf cfg.enable {
  #  home.sessionVariables.EDITOR = "nvim";
  #};

}
