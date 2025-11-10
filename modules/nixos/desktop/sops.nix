{
  flake,
  config,
  lib,
  ...
}:

{
  imports = [ flake.inputs.sops.nixosModules.sops ];

  options.nixos.desktop.sops.enable = lib.mkEnableOption "sops config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.sops.enable {

    sops.defaultSopsFile = ../../../secrets/var.yaml;
    sops.age.keyFile = "/home/znaniye/.config/sops/age/keys.txt";

    sops.secrets.tailscale-key = { };
    sops.secrets.ts-client-id = { };
    sops.secrets.ts-client-secret = { };
    sops.secrets.gh-token = { };
    sops.secrets.wireguard-private-key = { };
  };
}
