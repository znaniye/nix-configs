{
  config,
  lib,
  ...
}:
{

  options.nixos.desktop.syncthing = {
    enable = lib.mkEnableOption "syncthing config" // {
      default = config.nixos.desktop.enable;
    };
  };

  config = lib.mkIf config.nixos.desktop.syncthing.enable {

    services.syncthing = {
      enable = true;
      user = "${config.meta.username}";
      openDefaultPorts = true;
      dataDir = "/home/${config.meta.username}";
      folders = {
        "Code" = {
          path = "/home/znaniye/code";
          #devices = [ "device1" "device2" ];
        };
      };
    };

  };

}
