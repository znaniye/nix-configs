{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.shared.nix;
in
{
  options.shared.nix.enable = lib.mkEnableOption "shared nix/nixpkgs config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix = {
      package = lib.mkDefault pkgs.nixVersions.latest;

      optimise.automatic = true;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "root" ];
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
