{ config, lib, ... }:

let
  cfg = config.nixos.nix.remote-builders;
in
{
  options.nixos.nix.remote-builders.enable = lib.mkEnableOption "remote-builders config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix = {
      buildMachines = [
        {
          hostName = "golf";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          sshUser = "nixremote";
          sshKey = "/root/.ssh/nixremote.pub";
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
        }
      ];

      distributedBuilds = true;

      settings = {
        builders-use-substitutes = true;
      };
    };
  };
}
