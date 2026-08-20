{ pkgs }:
let
  pname = "pencil";
  version = "1.1.69";

  releaseBase = "https://github.com/highagency/pencil-desktop-releases/releases/download/v${version}";
  asset = "Pencil-${version}-linux-x86_64.AppImage";

  unfreePkgs = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  inherit (unfreePkgs) lib appimageTools fetchurl;

  src = fetchurl {
    hash = "sha256-h6wbMltvweK3rKFATyIWvGFTtcLJDqENHMsWGbGkumA=";
    url = "${releaseBase}/${asset}";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/pencil.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/pencil.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=pencil --no-sandbox %U'
    install -Dm444 \
      ${appimageContents}/usr/share/icons/hicolor/512x512/apps/pencil.png \
      -t $out/share/icons/hicolor/512x512/apps
  '';
  meta = {
    description = "Pencil.dev — AI-native design tool (design on canvas, land in code)";
    homepage = "https://pencil.dev";
    license = lib.licenses.unfree;
    mainProgram = "pencil";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
  passthru.penSchemaVersion = "2.14";
}
