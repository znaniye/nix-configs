{ self, ... }:

final: prev:
let
  inherit (prev.stdenv.hostPlatform) system isLinux;
in
{
  inherit (self.inputs.emacs-overlay.packages.${system}) emacsWithPackagesFromUsePackage;

  zls = self.inputs.zls.packages.${system}.default;
  zig = self.inputs.zig.packages.${system}."0.15.1";

  rtk = self.inputs.llm-agents.packages.${system}.rtk;

  pi-coding-agent = self.inputs.coding-agents.packages.${system}.pi-coding-agent;

  herdr = self.inputs.herdr.packages.${system}.herdr;

  inherit (import ./qasync.nix final prev) pythonPackagesExtensions;
}
// prev.lib.optionalAttrs isLinux {
  inherit (self.inputs.niri.packages.${system}) niri-unstable;

  pencil-cli = import ./pencil-cli.nix { pkgs = prev; };

  pencil = import ./pencil.nix { pkgs = prev; };
}
