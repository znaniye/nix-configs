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
  config = lib.mkIf cfg.enable {
    nix = {
      optimise.automatic = true;
      package = lib.mkDefault pkgs.nixVersions.latest;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://cache.numtide.com"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        trusted-users = [ "root" ];
      };
    };

    nixpkgs = {
      config.allowUnfree = true;
      overlays = [
        flake.outputs.overlays.default
      ];
    };
  };
  options.shared.nix.enable = lib.mkEnableOption "shared nix/nixpkgs config" // {
    default = true;
  };
}
