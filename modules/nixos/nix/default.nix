{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixos.nix;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nixos-rebuild-ng ];
    nix =
      let
        hostBasedJobs = if config.networking.hostName == "golf" then 3 else 1;
      in
      {
        # Leave nix builds as a background task
        daemonCPUSchedPolicy = "batch";
        # Reduce disk usage
        daemonIOSchedClass = "best-effort";
        daemonIOSchedPriority = 7;
        extraOptions = ''
          !include ${config.sops.secrets.freedom-github-http-auth-token.path}
        '';
        gc = {
          automatic = true;
          dates = "3:15";
          options = "--delete-older-than 30d";
          persistent = true;
          randomizedDelaySec = "15m";
        };
        settings = {
          auto-optimise-store = true;
          extra-platforms = [ "aarch64-linux" ];
          extra-substituters = [
            "https://nixos-raspberrypi.cachix.org"
          ];
          extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
          ];
          max-jobs = hostBasedJobs;
          max-silent-time = 1800;
          trusted-users = [ "@wheel" ];
        };
      };
    programs.git = {
      config =
        let
          rootToken = config.sops.secrets.gitea-pat-token.path;
          userToken = config.sops.secrets.gitea-pat-token-user.path;
          helper = ''!f() { if [ "$1" = get ]; then if [ -r ${rootToken} ]; then t=${rootToken}; elif [ -r ${userToken} ]; then t=${userToken}; else exit 0; fi; echo username=${config.nixos.home.username}; printf 'password='; cat $t; fi; }; f'';
        in
        {
          credential."http://192.168.68.111:3000".helper = helper;
          credential."https://gitea.znaniye.xyz".helper = helper;
        };
      enable = true;
    };
    sops = {
      age.keyFile = "/home/znaniye/.config/sops/age/keys.txt";
      defaultSopsFile = ../../../secrets/var.yaml;
      secrets.freedom-github-http-auth-token = {
        mode = "0400";
        owner = config.nixos.home.username;
      };
      secrets.gitea-pat-token = {
        mode = "0400";
        owner = "root";
      };
      secrets.gitea-pat-token-user = {
        key = "gitea-pat-token";
        mode = "0400";
        owner = config.nixos.home.username;
      };

    };
  };
  imports = [
    ./remote-builders.nix
  ];
  options.nixos.nix = {
    enable = lib.mkEnableOption "nix/nixpkgs config" // {
      default = true;
    };
  };
}
