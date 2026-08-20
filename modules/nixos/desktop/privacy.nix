{
  config,
  lib,
  pkgs,
  ...
}:
{

  config = lib.mkIf config.nixos.desktop.privacy.enable {

    environment.systemPackages = with pkgs; [ tor-browser ];
    services.tor = {
      client = {
        enable = true;
      };
      enable = true;
    };
  };
  options.nixos.desktop.privacy = {
    enable = lib.mkEnableOption "privacy stuff config" // {
      default = config.nixos.desktop.enable;
    };
  };

}
