{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.darwin.nix;
in
{
  options.darwin.nix.enable = lib.mkEnableOption "nix/nixpkgs config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix = {
      package = lib.mkDefault pkgs.nixVersions.latest;

      gc = {
        automatic = true;
        interval = {
          Hour = 3;
          Minute = 15;
        };
        options = "--delete-older-than 30d";
      };

      optimise.automatic = true;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@admin"
        ];
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://cache.numtide.com"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
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
