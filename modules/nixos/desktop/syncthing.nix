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
in
{
  options.nixos.desktop.syncthing = {
    enable = lib.mkEnableOption "syncthing config";

    cert = lib.mkOption {
      type = lib.types.path;
      default = defaultCert;
      description = "Path to Syncthing TLS cert (public).";
    };

    keySecretName = lib.mkOption {
      type = lib.types.str;
      default = defaultKeySecretName;
      description = "Name of the SOPS secret holding the Syncthing TLS private key.";
    };

    folder = lib.mkOption {
      type = lib.types.str;
      default = "/home/${user}/code";
      description = "Directory to sync.";
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "sendreceive"
        "sendonly"
        "receiveonly"
      ];
      default = "sendreceive";
      description = "Folder sync mode for this host.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = devices ? ${selfHost};
        message = "Host ${selfHost} is missing from modules/shared/syncthing-devices.nix.";
      }
    ];

    sops.secrets.${cfg.keySecretName} = {
      owner = user;
      mode = "0400";
    };

    services.syncthing = {
      enable = true;
      user = user;
      dataDir = "/home/${user}";
      configDir = "/home/${user}/.config/syncthing";
      openDefaultPorts = true;

      cert = toString cfg.cert;
      key = config.sops.secrets.${cfg.keySecretName}.path;

      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = peerDevices;

        folders.code = {
          path = cfg.folder;
          devices = lib.attrNames peerDevices;
          type = cfg.mode;
        };
      };
    };
  };
}
