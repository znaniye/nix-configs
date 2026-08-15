{ pkgs, zmk-nix }:
let
  inherit (pkgs) lib;

  tree = lib.sourceFilesBySuffices ../keyboards/corne [
    ".conf"
    ".keymap"
    ".overlay"
    ".yml"
    ".c"
    ".h"
    "CMakeLists.txt"
    "Kconfig"
  ];
in
zmk-nix.buildSplitKeyboard {
  name = "corne-firmware";

  src = pkgs.runCommand "corne-src" { } ''
    cp -r ${tree} $out
    chmod -R u+w $out
    install -m644 ${pkgs.corne-screen-assets}/*.c $out/src/
  '';

  board = "nice_nano@2.0.0//zmk";
  shield = "corne_%PART%";

  enableZmkStudio = true;

  zephyrDepsHash = "sha256-UZy/bhS2fwjY/WnTDPW1wJtXC7eDHM/fl7lSYg7eGRA=";

  meta = {
    description = "ZMK firmware for the Corne on nice!nano v2";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
