{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.nixos.desktop.syncthing;
  user = config.shared.meta.username;
  selfHost = config.networking.hostName;

  defaultCert = ../../../secrets/syncthing/${selfHost}.pem;
  defaultKeySecretName = "syncthing-key-${selfHost}";

  allHosts = flake.outputs.nixosConfigurations or { };

  peers = lib.filterAttrs (
    name: host:
    name != selfHost
    && (host.config.nixos.desktop.syncthing.enable or false)
    && (host.config.nixos.desktop.syncthing.deviceId or null) != null
  ) allHosts;

  peerDevices = lib.mapAttrs (_: host: {
    id = host.config.nixos.desktop.syncthing.deviceId;
  }) peers;
in
{
  options.nixos.desktop.syncthing = {
    enable = lib.mkEnableOption "syncthing config";

    deviceId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "This host's Syncthing device ID. Discovered by other hosts.";
    };

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
        assertion = cfg.deviceId != null;
        message = "Set nixos.desktop.syncthing.deviceId for host ${selfHost}.";
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
