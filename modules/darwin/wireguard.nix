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

  intranetDomain = "intranet.freedom.ind.br";
  intranetResolver = "192.168.0.240";

  supervisor = pkgs.writeShellScript "wg0-supervisor" ''
    export PATH=${pkgs.wireguard-tools}/bin:${pkgs.wireguard-go}/bin:${config.environment.systemPath}

    trap 'wg-quick down wg0 2>/dev/null; exit 0' TERM INT

    [ -r ${lib.escapeShellArg privateKeyFile} ] || exit 1

    wg-quick down wg0 2>/dev/null || true
    wg-quick up wg0 || exit 1

    while :; do
      sleep 20 & wait $!

      real=$(cat /var/run/wireguard/wg0.name 2>/dev/null)
      [ -n "$real" ] || exit 1

      wg show "$real" latest-handshakes 2>/dev/null |
        awk -v now=$(date +%s) '$2 && now - $2 < 180 { ok = 1 } END { exit !ok }' || exit 1
    done
  '';
in
{
  config = lib.mkMerge [
    {
      home-manager.users.${username}.sops.secrets.${secretName}.path = privateKeyFile;
    }

    (lib.mkIf cfg.enable {
      environment.etc."resolver/${intranetDomain}".text = ''
        nameserver ${intranetResolver}
      '';
      launchd.daemons.wg-quick-wg0.serviceConfig = {
        KeepAlive = lib.mkForce true;
        ProgramArguments = lib.mkForce [
          "/bin/sh"
          "-c"
          "exec ${supervisor}"
        ];
        RunAtLoad = true;
        ThrottleInterval = 30;
      };
      networking.wg-quick.interfaces.wg0 = {
        address = [ "192.168.240.15/32" ];
        peers = [
          {
            allowedIPs = [
              "192.168.0.0/23"
              "192.168.150.0/24"
              "192.168.7.0/24"
            ];
            endpoint = "hep09fmme67.sn.mynetname.net:13231";
            persistentKeepalive = 10;
            publicKey = "7poZW/qGM9HyZuKaA7ryP+EEtuK6b4E+G2sMcbNr6iM=";
          }
        ];
        privateKeyFile = privateKeyFile;
      };
    })
  ];
  options.darwin.wireguard.enable = lib.mkEnableOption "wireguard config (wg-quick via launchd)";
}
