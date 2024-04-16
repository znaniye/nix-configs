{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;

      layout = "br";
      xkbVariant = "";

      displayManager = {
        defaultSession = "none+i3";
        autoLogin.enable = true;
        autoLogin.user = "znaniye";
      };

      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        extraPackages = with pkgs; [
          dmenu # application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock # default i3 screen locker
          i3blocks # if you are planning on using i3blocks over i3status
        ];
      };
    };
  };
}
