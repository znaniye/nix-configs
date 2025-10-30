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
      (with pkgs; [
        ocaml
        ocamlformat_0_26_1
      ])
      ++ (with pkgs.ocamlPackages; [
        ocaml-lsp
        utop
      ]);
  };
}
