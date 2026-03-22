{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixos.nix;
in
{
  imports = [
    ./remote-builders.nix
  ];

  options.nixos.nix = {
    enable = lib.mkEnableOption "nix/nixpkgs config" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nixos-rebuild-ng ];

    sops = {
      defaultSopsFile = ../../../secrets/var.yaml;
      age.keyFile = "/home/znaniye/.config/sops/age/keys.txt";
      secrets.freedom-github-http-auth-token = {
        owner = config.nixos.home.username;
        mode = "0400";
      };

    };

    nix =
      let
        hostBasedJobs = if config.networking.hostName == "felix" then 1 else "auto";
      in
      {
        package = pkgs.nixVersions.latest;
        gc = {
          automatic = true;
          persistent = true;
          randomizedDelaySec = "15m";
          dates = "3:15";
          options = "--delete-older-than 30d";
        };
        # Optimise nix-store via service
        optimise.automatic = true;
        # Reduce disk usage
        daemonIOSchedClass = "best-effort";
        daemonIOSchedPriority = 7;
        # Leave nix builds as a background task
        daemonCPUSchedPolicy = "batch";

        extraOptions = ''
          experimental-features = nix-command flakes
          !include ${config.sops.secrets.freedom-github-http-auth-token.path}
        '';

        settings = {
          trusted-users = [
            "root"
            "@wheel"
          ];
          extra-platforms = [ "aarch64-linux" ];
          auto-optimise-store = true;
          max-jobs = hostBasedJobs;
        };
      };

    nixpkgs = {
      config.allowUnfree = true;
      overlays = [
        flake.outputs.overlays.default
      ];
    };
  };
}
