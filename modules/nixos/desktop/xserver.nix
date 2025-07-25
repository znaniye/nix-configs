{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nixos.desktop.xserver.enable = lib.mkEnableOption "xserver config" // {
    default = false; # config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.xserver.enable {
    services = {
      displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = true;
          user = config.meta.username;
        };
      };

      xserver = {
        enable = true;

        xkb = {
          variant = "";
          layout = "br";
        };

        windowManager.i3 = {
          enable = true;
          package = pkgs.i3-gaps;
        };
      };
    };

    environment.systemPackages = with pkgs; [ xclip ];
  };
}
