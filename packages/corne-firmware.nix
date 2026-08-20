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
  board = "nice_nano@2.0.0//zmk";
  enableZmkStudio = true;
  meta = {
    description = "ZMK firmware for the Corne on nice!nano v2";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
  name = "corne-firmware";
  shield = "corne_%PART%";
  src = pkgs.runCommand "corne-src" { } ''
    cp -r ${tree} $out
    chmod -R u+w $out
    install -m644 ${pkgs.corne-screen-assets}/*.c $out/src/
  '';
  zephyrDepsHash = "sha256-UZy/bhS2fwjY/WnTDPW1wJtXC7eDHM/fl7lSYg7eGRA=";
}
