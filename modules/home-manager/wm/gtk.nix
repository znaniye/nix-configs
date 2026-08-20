{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home-manager.wm.gtk.enable {

    gtk = {
      enable = true;
      iconTheme = {
        name = "Nordzy-dark";
        package = pkgs.nordzy-icon-theme;
      };
      theme = {
        name = "Nordic";
        package = pkgs.nordic;
      };
    };

    services.xsettingsd = {
      enable = true;
      settings = with config; {
        # When running, most GNOME/GTK+ applications prefer those settings
        # instead of *.ini files
        "Net/IconThemeName" = gtk.iconTheme.name;
        "Net/ThemeName" = gtk.theme.name;
        #"Gtk/CursorThemeName" = xsession.pointerCursor.name;
      };
    };
  };
  options.home-manager.wm.gtk.enable = lib.mkEnableOption "GTK theme config" // {
    default = config.home-manager.wm.enable;
  };
}
