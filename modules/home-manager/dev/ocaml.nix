{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.ocaml.enable = lib.mkEnableOption "ocaml config" // {
    default = config.home-manager.dev.enable;
  };

  config = lib.mkIf config.home-manager.dev.ocaml.enable {
    home.packages =
      (with pkgs; [ ocaml ])
      ++ (with pkgs.ocamlPackages; [
        lsp
        utop
      ]);
  };
}
