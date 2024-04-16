{ pkgs, lib, ... }:
{
  home.pointerCursor = {
    package = pkgs.breeze-qt5;
    name = "Breeze";
    size = 12;
  };

  home.file."/home/znaniye/.icons/default".source = "${lib.getBin pkgs.breeze-qt5}/share/icons/breeze_cursors";

  #home.file."/home/znaniye/.icons/Breeze".source = "${lib.getBin pkgs.breeze-qt5}/share/icons/breeze_cursors";
}
