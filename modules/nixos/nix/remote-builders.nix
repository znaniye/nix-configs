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
      # Only felix offloads builds to golf over the LAN.
      buildMachines = lib.optionals (config.networking.hostName == "felix") [
        {
          hostName = "192.168.68.107"; # golf (wired-golf static IP)
          system = "x86_64-linux";
          protocol = "ssh-ng";
          sshUser = "nixremote";
          sshKey = "/root/.ssh/id_ed25519"; # matching pubkey authorized as root@felix on golf
          maxJobs = 3;
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
