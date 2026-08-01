{
  config,
  lib,
  ...
}:
let
  cfg = config.darwin.desktop.syncthing;

  username = config.darwin.home.username;
  selfHost = "massan";
  secretName = "syncthing-key-${selfHost}";
  keyFile = "${config.home-manager.users.${username}.xdg.configHome}/secrets/${secretName}";

  devices = import ../shared/syncthing-devices.nix;
  peerDevices = lib.mapAttrs (_: id: { inherit id; }) (
    lib.filterAttrs (name: _: name != selfHost) devices
  );

  relFolder = lib.removePrefix "/Users/${username}/" cfg.folder;
in
{
  options.darwin.desktop.syncthing = {
    enable = lib.mkEnableOption "syncthing config";

    folder = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${username}/code";
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

    ignore = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = import ../shared/syncthing-ignore.nix;
      description = "Patterns written to the folder's .stignore (regenerable/heavy dirs).";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      sops.secrets.${secretName}.path = keyFile;

      home.file = lib.mkIf (cfg.ignore != [ ]) {
        "${relFolder}/.stignore".text = lib.concatStringsSep "\n" cfg.ignore + "\n";
      };

      services.syncthing = {
        enable = true;

        cert = toString ../shared/syncthing-certs/massan.pem;
        key = keyFile;

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
  };
}
