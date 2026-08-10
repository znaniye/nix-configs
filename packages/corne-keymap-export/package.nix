{ pkgs, zmk-studio-api }:
let
  python = pkgs.python3.withPackages (_: [ zmk-studio-api ]);
in
pkgs.writeShellApplication {
  name = "corne-keymap-export";

  text = ''
    exec ${python}/bin/python3 ${./export.py} "$@"
  '';
}
