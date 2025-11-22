{ self, ... }:

final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  inherit (self.inputs.emacs-overlay.packages.${system}) emacsWithPackagesFromUsePackage;
  inherit (self.inputs.niri.packages.${system}) niri-stable;

  zls = self.inputs.zls.packages.${system}.default;
  zig = self.inputs.zig.packages.${system}."0.15.1";

  openfreebuds = prev.openfreebuds.overrideAttrs (_: {
    pythonRelaxDeps = true;
    postInstall = ''
      mkdir -p  $out/share/applications
      mv openfreebuds_qt/assets/pw.mmk.OpenFreebuds.desktop $out/share/applications
    '';
  });

}
