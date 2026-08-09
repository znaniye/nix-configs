{ pkgs, zmk-nix }:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
in
zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
  name = "corne-firmware";

  src = lib.sourceFilesBySuffices ../keyboards/corne [
    ".conf"
    ".keymap"
    ".overlay"
    ".yml"
  ];

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
