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

  stignore = builtins.toFile "syncthing-code.stignore" (
    lib.concatStringsSep "\n" cfg.ignore + "\n"
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

    ignore = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = import ../shared/syncthing-ignore.nix;
      description = "Patterns written to the folder's .stignore (regenerable/heavy dirs).";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      sops.secrets.${secretName}.path = keyFile;

      home.activation.syncthingStignore = lib.mkIf (cfg.ignore != [ ]) {
        after = [ "linkGeneration" ];
        before = [ ];
        data = ''
          $DRY_RUN_CMD mkdir -p "$HOME/${relFolder}"
          $DRY_RUN_CMD install -m 0644 ${stignore} "$HOME/${relFolder}/.stignore"
        '';
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
