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

  stignore = builtins.toFile "syncthing-code.stignore" (lib.concatStringsSep "\n" cfg.ignore + "\n");
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.activation.syncthingStignore = lib.mkIf (cfg.ignore != [ ]) {
        after = [ "linkGeneration" ];
        before = [ ];
        data = ''
          $DRY_RUN_CMD mkdir -p "$HOME/${relFolder}"
          $DRY_RUN_CMD install -m 0644 ${stignore} "$HOME/${relFolder}/.stignore"
        '';
      };
      services.syncthing = {
        cert = toString ../shared/syncthing-certs/massan.pem;
        enable = true;
        key = keyFile;
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
      };
      sops.secrets.${secretName}.path = keyFile;
    };
  };
  options.darwin.desktop.syncthing = {
    enable = lib.mkEnableOption "syncthing config";
    folder = lib.mkOption {
      default = "/Users/${username}/code";
      description = "Directory to sync.";
      type = lib.types.str;
    };
    ignore = lib.mkOption {
      default = import ../shared/syncthing-ignore.nix;
      description = "Patterns written to the folder's .stignore (regenerable/heavy dirs).";
      type = lib.types.listOf lib.types.str;
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
