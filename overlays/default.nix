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
  inherit (import ./qasync.nix final prev) pythonPackagesExtensions;
  corne-update = self.inputs.zmk-nix.packages.${system}.update;
  herdr = self.inputs.herdr.packages.${system}.herdr;
  pi-coding-agent = self.inputs.coding-agents.packages.${system}.pi-coding-agent;
  rtk = self.inputs.llm-agents.packages.${system}.rtk;
  zig = self.inputs.zig.packages.${system}."0.15.1";
  zls = self.inputs.zls.packages.${system}.default;
  zmk-nix = self.inputs.zmk-nix.legacyPackages.${system};
}
// lib.optionalAttrs isLinux {
  corne-flash = self.inputs.zmk-nix.packages.${system}.flash.override {
    firmware = final.corne-firmware;
  };
}
