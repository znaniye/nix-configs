{ config, lib, ... }:

let
  cfg = config.nixos.nix.remote-builders;
in
{
  config = lib.mkIf cfg.enable {
    nix = {
      # Only felix offloads builds to golf over the LAN.
      buildMachines = lib.optionals (config.networking.hostName == "felix") [
        {
          hostName = "192.168.68.107"; # golf (wired-golf static IP)
          maxJobs = 3;
          protocol = "ssh-ng";
          sshKey = "/root/.ssh/id_ed25519"; # matching pubkey authorized as root@felix on golf
          sshUser = "nixremote";
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          system = "x86_64-linux";
        }
      ];

      distributedBuilds = true;

      settings = {
        builders-use-substitutes = true;
      };
    };
  };
  options.nixos.nix.remote-builders.enable = lib.mkEnableOption "remote-builders config" // {
    default = true;
  };
}
