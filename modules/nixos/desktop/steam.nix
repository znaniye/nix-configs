{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.nixos.desktop.steam;
in
{
  options.nixos.desktop.steam = {
    enable = lib.mkEnableOption "Steam config" // {
      default = config.nixos.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gamescope
      mangohud
    ];

    programs = {

      gamescope = {
        args = [ "--rt" ];
        capSysNice = true;
      };

      steam = {

        enable = true;
        remotePlay.openFirewall = true;
        package = pkgs.steam.override {
          extraArgs = "-system-composer";
        };

        gamescopeSession = {
          enable = true;
          args = [
            "--fsr-sharpness 10"
            "-U"
            "--adaptive-sync"
          ];
        };
      };
    };
  };
}
