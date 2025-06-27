{
  services = {
    xserver = {
      enable = true;
      layout = "br";
      xkbVariant = "";

      displayManager = {
        gdm.enable = true;
        autoLogin.enable = true;
        autoLogin.user = "znaniye";
      };

      desktopManager.gnome.enable = true;
    };
  };
}
