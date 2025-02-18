{pkgs}: let
  organize-downloads = pkgs.writeScriptBin "organize-downloads" ''
    #!${pkgs.bash}/bin/bash

    cd ~/Downloads

    mkdir -p images
    mv *.{png,jpg,jpeg,gif} images/ 2>/dev/null

    mkdir -p documents
    mv *.{pdf,doc,docx,txt} documents/ 2>/dev/null

    mkdir -p compressed
    mv *.{zip,rar,7z,tar,gz} compressed/ 2>/dev/null

  '';
in [
  organize-downloads
]
