{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.desktop.syncthing;
  user = config.shared.meta.username;
  selfHost = config.networking.hostName;

  defaultCert = ../../shared/syncthing-certs/${selfHost}.pem;
  defaultKeySecretName = "syncthing-key-${selfHost}";

  devices = import ../../shared/syncthing-devices.nix;
  peerDevices = lib.mapAttrs (_: id: { inherit id; }) (
    lib.filterAttrs (name: _: name != selfHost) devices
  );

  stignore = builtins.toFile "syncthing-code.stignore" (lib.concatStringsSep "\n" cfg.ignore + "\n");
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = devices ? ${selfHost};
        message = "Host ${selfHost} is missing from modules/shared/syncthing-devices.nix.";
      }
    ];
    services.syncthing = {
      cert = toString cfg.cert;
      configDir = "/home/${user}/.config/syncthing";
      dataDir = "/home/${user}";
      enable = true;
      key = config.sops.secrets.${cfg.keySecretName}.path;
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = peerDevices;

        folders.code = {
          devices = lib.attrNames peerDevices;
          ignorePerms = true;
          path = cfg.folder;
          type = cfg.mode;
        };
      };
      user = user;
    };
    sops.secrets.${cfg.keySecretName} = {
      mode = "0400";
      owner = user;
    };
    system.activationScripts.syncthingStignore.text = lib.optionalString (cfg.ignore != [ ]) ''
      mkdir -p ${cfg.folder}
      chown ${user} ${cfg.folder}
      install -o ${user} -m 0644 ${stignore} ${cfg.folder}/.stignore
    '';
  };
  options.nixos.desktop.syncthing = {
    cert = lib.mkOption {
      default = defaultCert;
      description = "Path to Syncthing TLS cert (public).";
      type = lib.types.path;
    };
    enable = lib.mkEnableOption "syncthing config";
    folder = lib.mkOption {
      default = "/home/${user}/code";
      description = "Directory to sync.";
      type = lib.types.str;
    };
    ignore = lib.mkOption {
      default = import ../../shared/syncthing-ignore.nix;
      description = "Patterns written to the folder's .stignore (regenerable/heavy dirs).";
      type = lib.types.listOf lib.types.str;
    };
    keySecretName = lib.mkOption {
      default = defaultKeySecretName;
      description = "Name of the SOPS secret holding the Syncthing TLS private key.";
      type = lib.types.str;
    };
    mode = lib.mkOption {
      default = "sendreceive";
      description = "Folder sync mode for this host.";
      type = lib.types.enum [
        "sendreceive"
        "sendonly"
        "receiveonly"
      ];
    };
  };
}
