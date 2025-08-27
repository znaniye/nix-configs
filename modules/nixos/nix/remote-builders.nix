{ config, lib, ... }:

let
  cfg = config.nixos.nix.remote-builders;
in
{
  options.nixos.nix.remote-builders.enable =
    lib.mkEnableOption "remote-builders config for nixpkgs"
    // {
      default = false;
    };

  config = lib.mkIf cfg.enable {
    nix = {
      buildMachines = [
        {
          hostName = "golf";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          maxJobs = 16;
          # base64 -w0 /etc/ssh/ssh_host_<type>_key.pub
          publicHostKey = "";
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
