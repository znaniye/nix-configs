{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixos.desktop.greetd.enable = lib.mkEnableOption "greetd + tuigreet" // {
    default = config.nixos.desktop.wayland.enable;
  };

  config = lib.mkIf config.nixos.desktop.greetd.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd niri-session";
          user = "greeter";
        };
      };
    };

    environment.systemPackages = [ pkgs.tuigreet ];
  };
}
