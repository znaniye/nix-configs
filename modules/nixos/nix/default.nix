{
  config,
  lib,
  libEx,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.nixos.nix;
in
{
  imports = [
    #./remote-builders.nix #TODO:
  ];

  options.nixos.nix = {
    enable = lib.mkEnableOption "nix/nixpkgs config" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ];

    nix = {
      gc = {
        automatic = true;
        persistent = true;
        randomizedDelaySec = "15m";
        dates = "3:15";
        options = "--delete-older-than 7d";
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
      '';

      settings = {
        trusted-users = [
          "root"
          "@wheel"
        ];
        auto-optimise-store = true;
      };
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      flake.outputs.overlays.default
      flake.inputs.emacs-overlay.overlays.default
      flake.inputs.niri.overlays.niri
      flake.inputs.zig.overlays.default
    ];
  };
}
