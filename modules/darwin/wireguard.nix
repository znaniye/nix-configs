{
  config,
  lib,
  ...
}:
let
  cfg = config.darwin.wireguard;

  username = config.darwin.home.username;
  secretName = "wireguard-private-key-felix";
  privateKeyFile = "${config.home-manager.users.${username}.xdg.configHome}/secrets/${secretName}";
in
{
  options.darwin.wireguard.enable = lib.mkEnableOption "wireguard config (wg-quick via launchd)";

  config = lib.mkMerge [
    {
      home-manager.users.${username}.sops.secrets.${secretName}.path = privateKeyFile;
    }

    (lib.mkIf cfg.enable {
      networking.wg-quick.interfaces.wg0 = {
        address = [ "192.168.240.15/32" ];
        dns = [
          "192.168.0.240"
          "intranet.freedom.ind.br"
        ];
        privateKeyFile = privateKeyFile;
        peers = [
          {
            publicKey = "7poZW/qGM9HyZuKaA7ryP+EEtuK6b4E+G2sMcbNr6iM=";
            allowedIPs = [
              "192.168.0.0/23"
              "192.168.150.0/24"
            ];
            endpoint = "hep09fmme67.sn.mynetname.net:13231";
            persistentKeepalive = 10;
          }
        ];
      };

      launchd.daemons.wg-quick-wg0.serviceConfig.KeepAlive = lib.mkForce true;
    })
  ];
}
