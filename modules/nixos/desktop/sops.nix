{
  config,
  flake,
  lib,
  ...
}:

{
  config = lib.mkIf config.nixos.desktop.sops.enable {

    sops.age.keyFile = "/home/znaniye/.config/sops/age/keys.txt";
    sops.defaultSopsFile = ../../../secrets/var.yaml;
    sops.secrets.gh-token = { };
    sops.secrets.ossystems-headscale-key = { };
    sops.secrets.tailscale-key = { };
    sops.secrets.ts-client-id = { };
    sops.secrets.ts-client-secret = { };
    sops.secrets.wifi = { };
  };
  imports = [ flake.inputs.sops.nixosModules.sops ];
  options.nixos.desktop.sops.enable = lib.mkEnableOption "sops config" // {
    default = config.nixos.desktop.enable;
  };
}
