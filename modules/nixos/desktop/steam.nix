{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixos.desktop.steam;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gamescope
    ];

    programs = {
      gamescope = {
        args = [ "--rt" ];
        capSysNice = true;
      };

      steam = {

        enable = true;
        gamescopeSession = {
          args = [
            "--fsr-sharpness 10"
            "-U"
            "--adaptive-sync"
          ];
          enable = true;
        };
        package = pkgs.steam.override {
          extraArgs = "-system-composer";
        };
        remotePlay.openFirewall = true;
      };
    };
  };
  options.nixos.desktop.steam = {
    enable = lib.mkEnableOption "Steam config" // {
      default = config.nixos.desktop.enable;
    };
  };
}
