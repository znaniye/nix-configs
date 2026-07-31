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
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      sops.secrets.${secretName}.path = keyFile;

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
