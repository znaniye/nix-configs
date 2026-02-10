{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.home-manager.wm.gtk.enable = lib.mkEnableOption "GTK theme config" // {
    default = config.home-manager.wm.enable;
  };

  config = lib.mkIf config.home-manager.wm.gtk.enable {

    gtk = {
      enable = true;
      theme = {
        package = pkgs.nordic;
        name = "Nordic";
      };
      iconTheme = {
        package = pkgs.nordzy-icon-theme;
        name = "Nordzy-dark";
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
}
