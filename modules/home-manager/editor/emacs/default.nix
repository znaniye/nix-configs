{
  config,
  lib,
  pkgs,
  ...
}:
let
  emacsWithPackages = pkgs.emacsWithPackagesFromUsePackage {
    config = ./settings.org;
  };
in
{
  options.home-manager.editor.emacs.enable = lib.mkEnableOption "emacs config" // {
    default = true;
  };

  config = lib.mkIf config.home-manager.editor.emacs.enable {
    programs.emacs = {
      enable = true;
      package = emacsWithPackages;
    };

    home.file = {
      ".emacs.d/init.el".text = "(org-babel-load-file \"~/.emacs.d/settings.org\")";

      ".emacs.d/settings.org" = {
        source = ./settings.org;

        onChange = ''
          # We need to ensure we regenerate the Emacs Lisp file for the changes be
          # applied in next start.
          rm -f ~/.emacs.d/settings.el

          # Remove the ELPA downloaded files so we don't leave old ones.
          rm -rf ~/.emacs.d/elpa
        '';
      };
    };

  };
}
