{ self, ... }:

final: prev:
let
  inherit (prev) lib;
  inherit (prev.stdenv.hostPlatform) system isLinux;

  inherit (final) callPackage;
in
lib.filesystem.packagesFromDirectoryRecursive {
  inherit callPackage;
  directory = ../packages;
}
// {
  inherit (self.inputs.emacs-overlay.packages.${system}) emacsWithPackagesFromUsePackage;

  zls = self.inputs.zls.packages.${system}.default;
  zig = self.inputs.zig.packages.${system}."0.15.1";

  rtk = self.inputs.llm-agents.packages.${system}.rtk;

  pi-coding-agent = self.inputs.coding-agents.packages.${system}.pi-coding-agent;

  herdr = self.inputs.herdr.packages.${system}.herdr;

  zmk-nix = self.inputs.zmk-nix.legacyPackages.${system};
  corne-update = self.inputs.zmk-nix.packages.${system}.update;

  inherit (import ./qasync.nix final prev) pythonPackagesExtensions;
}
// lib.optionalAttrs isLinux {
  corne-flash = self.inputs.zmk-nix.packages.${system}.flash.override {
    firmware = final.corne-firmware;
  };
}
