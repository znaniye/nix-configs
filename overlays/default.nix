{ self, ... }:

final: prev: {

  zls = self.inputs.zls.packages.${prev.stdenv.hostPlatform.system}.default;

  openfreebuds = prev.openfreebuds.overrideAttrs (_: {
    pythonRelaxDeps = true;
    postInstall = ''
      mkdir -p  $out/share/applications
      mv openfreebuds_qt/assets/pw.mmk.OpenFreebuds.desktop $out/share/applications
    '';
  });

}
