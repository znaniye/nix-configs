{ self, ... }:

final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  inherit (self.inputs.emacs-overlay.packages.${system}) emacsWithPackagesFromUsePackage;
  inherit (self.inputs.niri.packages.${system}) niri-unstable;

  zls = self.inputs.zls.packages.${system}.default;
  zig = self.inputs.zig.packages.${system}."0.15.1";

  opencode = self.inputs.llm-agents.packages.${system}.opencode;

  pi-coding-agent = self.inputs.coding-agents.packages.${system}.pi-coding-agent;

  herdr = self.inputs.herdr.packages.${system}.herdr;

  pencil-cli = import ./pencil-cli.nix { pkgs = prev; };

  pencil = import ./pencil.nix { pkgs = prev; };

  inherit (import ./qasync.nix final prev) pythonPackagesExtensions;
}
