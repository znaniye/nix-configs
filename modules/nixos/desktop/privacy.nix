{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.nixos.desktop.privacy = {
    enable = lib.mkEnableOption "privacy stuff config" // {
      default = config.nixos.desktop.enable;
    };
  };

  config = lib.mkIf config.nixos.desktop.privacy.enable {

    services.tor = {
      enable = true;
      client = {
        enable = true;
      };
    };

    environment.systemPackages = with pkgs; [ tor-browser ];
  };

}
