{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.darwin.wireguard;

  username = config.darwin.home.username;
  secretName = "wireguard-private-key-felix";
  privateKeyFile = "${config.home-manager.users.${username}.xdg.configHome}/secrets/${secretName}";

  healthcheck = pkgs.writeShellScript "wg0-healthcheck" ''
    export PATH=${pkgs.wireguard-tools}/bin:${pkgs.wireguard-go}/bin:${config.environment.systemPath}

    real=$(cat /var/run/wireguard/wg0.name 2>/dev/null)
    if [ -n "$real" ] && wg show "$real" latest-handshakes 2>/dev/null |
       awk -v now=$(date +%s) '$2 && now - $2 < 180 { ok = 1 } END { exit !ok }'; then
      exit 0
    fi

    wg-quick down wg0 2>/dev/null || true
    wg-quick up wg0
  '';
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
              "192.168.7.0/24"
            ];
            endpoint = "hep09fmme67.sn.mynetname.net:13231";
            persistentKeepalive = 10;
          }
        ];
      };

      launchd.daemons.wg-quick-wg0.serviceConfig = {
        ProgramArguments = lib.mkForce [ "${healthcheck}" ];
        KeepAlive = lib.mkForce false;
        RunAtLoad = true;
        StartInterval = 60;
      };
    })
  ];
}
