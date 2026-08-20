{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.nixos.desktop.greetd.enable {
    environment.systemPackages = [ pkgs.tuigreet ];
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd niri-session";
          user = "greeter";
        };
      };
    };
  };
  options.nixos.desktop.greetd.enable = lib.mkEnableOption "greetd + tuigreet" // {
    default = config.nixos.desktop.wayland.enable;
  };
}
