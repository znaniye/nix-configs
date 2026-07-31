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

  keepAlive = pkgs.writeShellScript "wg-quick-wg0-keepalive" ''
    export PATH=${pkgs.wireguard-tools}/bin:${pkgs.wireguard-go}/bin:${config.environment.systemPath}
    trap 'wg-quick down wg0 2>/dev/null; exit 0' TERM INT

    wg-quick down wg0 2>/dev/null || true
    wg-quick up wg0 || exit 1

    while :; do
      sleep 20
      hs=$(wg show wg0 latest-handshakes 2>/dev/null | awk '{print $2}' | sort -n | tail -1)
      [ -n "$hs" ] || exit 1
      [ "$(( $(date +%s) - hs ))" -lt 180 ] || exit 1
    done
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
            ];
            endpoint = "hep09fmme67.sn.mynetname.net:13231";
            persistentKeepalive = 10;
          }
        ];
      };

      launchd.daemons.wg-quick-wg0.serviceConfig = {
        ProgramArguments = lib.mkForce [ "${keepAlive}" ];
        KeepAlive = lib.mkForce true;
        RunAtLoad = true;
        ThrottleInterval = 15;
      };
    })
  ];
}
