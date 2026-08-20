{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.home-manager.editor.emacs.enable {

    programs.emacs = {
      enable = true;
      package = pkgs.emacsWithPackagesFromUsePackage {
        config = ./init.el;
        defaultInitFile = true;
      };
    };

  };
  options.home-manager.editor.emacs.enable = lib.mkEnableOption "emacs config" // {
    default = false;
  };
}
