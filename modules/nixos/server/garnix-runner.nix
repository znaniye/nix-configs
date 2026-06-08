{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.nixos.server.garnixRunner;
in
{
  # Standalone garnix action-runner: runs the krun/KVM microVMs that execute
  # garnix actions, without the rest of the garnix coordinator. Used on a host
  # (golf) that takes over actions + remote builds from a low-RAM coordinator
  # (tortinha). The action-runner module is self-contained — it only pulls in
  # custom-gc and the garnix flake inputs, not the Haskell/opensearch overlay.
  imports = [
    "${flake.inputs.garnix-ci}/nix/modules/action-runner.nix"
    "${flake.inputs.garnix-ci}/nix/modules/custom-gc.nix"
  ];

  options.nixos.server.garnixRunner = {
    enable = lib.mkEnableOption "standalone garnix action-runner";

    authorizedKey = lib.mkOption {
      type = lib.types.str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2DPx198YXU9f0dCAwWhPBIVswQ/H9KVuaXe19Brhme garnix-action-runner@golf";
      description = ''
        Public key of the garnix coordinator allowed to ssh into the
        action-runner user and submit work. Matches the private key the
        coordinator reads from the garnix-action-runner-ssh sops secret.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    _module.args.flakeInputs = flake.inputs.garnix-ci.inputs;

    # Enables the action-runner user, podman + crun/libkrun runtime, and (via the
    # module) garnix.custom-gc with its hourly timer.
    garnix.actionRunner.enable = true;
    garnix.actionRunner.authorizedKey = cfg.authorizedKey;
  };
}
