{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  dontConfigure = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes/Nordic
    cp -a index.theme gtk-3.0 gtk-4.0 $out/share/themes/Nordic/
    runHook postInstall
  '';
  meta = {
    description = "Gtk and KDE themes using the Nord color pallete";
    homepage = "https://github.com/EliverLara/Nordic";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
  pname = "nordic";
  src = fetchFromGitHub {
    hash = "sha256-OkXjwaoXyWfTgNkeU+ab+uv+U/5OaJ8oTt/G8YLz84o=";
    name = "Nordic";
    owner = "EliverLara";
    repo = "nordic";
    rev = "d9b5c42cebf9a165bcce7b6b8a019f5cfd5b789c";
  };
  version = "2.2.0-unstable-2025-05-05";
}
