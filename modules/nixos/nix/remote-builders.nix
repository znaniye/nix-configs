{ config, lib, ... }:

let
  cfg = config.nixos.nix.remote-builders;
in
{
  options.nixos.nix.remote-builders.enable =
    lib.mkEnableOption "remote-builders config for nixpkgs"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    # Compile via remote builders+Tailscale
    nix = {
      buildMachines = [
        {
          hostName = "golf";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          maxJobs = 16;
          # base64 -w0 /etc/ssh/ssh_host_<type>_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSURXWWZ5dy9JYVZuQm9HREhwYjJDQmE5TTM0RHR5OVBObDR3WmhKL1Zjd1Qgcm9vdEBmZWxpeAo=";
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
