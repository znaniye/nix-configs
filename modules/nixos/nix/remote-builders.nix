{ config, lib, ... }:

let
  cfg = config.nixos.nix.remote-builders;
in
{
  config = lib.mkIf cfg.enable {
    nix = {
      buildMachines = [
        {
          hostName = "23.145.72.22"; # srv-fabio-1a
          maxJobs = 8;
          protocol = "ssh-ng";
          sshKey = "/root/.ssh/id_ed25519"; # matching pubkey authorized as samuel on srv-fabio-1a
          sshUser = "samuel";
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          system = "x86_64-linux";
        }
      ]
      ++ lib.optionals (config.networking.hostName == "felix") [
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

    programs.ssh.knownHosts.srv-fabio-1a = {
      hostNames = [
        "srv-fabio-1a"
        "23.145.72.22"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0NrgQrXlkQQ28PY1cBhuJKyjDsXf9R4ySQBzlSsM+B";
    };
  };
  options.nixos.nix.remote-builders.enable = lib.mkEnableOption "remote-builders config" // {
    default = true;
  };
}
