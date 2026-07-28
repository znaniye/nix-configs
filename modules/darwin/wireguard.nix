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

  wgConf = pkgs.writeText "wg0.conf" ''
    [Interface]
    Address = 192.168.240.15/32
    DNS = 192.168.0.240, intranet.freedom.ind.br
    PostUp = ${pkgs.wireguard-tools}/bin/wg set %i private-key ${privateKeyFile}

    [Peer]
    PublicKey = 7poZW/qGM9HyZuKaA7ryP+EEtuK6b4E+G2sMcbNr6iM=
    AllowedIPs = 192.168.0.0/23, 192.168.150.0/24
    Endpoint = hep09fmme67.sn.mynetname.net:13231
    PersistentKeepalive = 10
  '';
in
{
  options.darwin.wireguard.enable = lib.mkEnableOption "wireguard config (wg-quick via launchd)";

  config = lib.mkMerge [
    {
      home-manager.users.${username}.sops.secrets.${secretName}.path = privateKeyFile;
    }

    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.wireguard-tools
        pkgs.wireguard-go
      ];

      launchd.daemons.wireguard-wg0 = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.wireguard-tools}/bin/wg-quick"
            "up"
            "${wgConf}"
          ];
          RunAtLoad = true;
          KeepAlive = false;
          StandardOutPath = "/var/log/wireguard-wg0.log";
          StandardErrorPath = "/var/log/wireguard-wg0.log";
          EnvironmentVariables.PATH = lib.mkForce (
            lib.makeBinPath [
              pkgs.wireguard-tools
              pkgs.wireguard-go
              pkgs.bash
              pkgs.coreutils
            ]
            + ":/usr/bin:/bin:/usr/sbin:/sbin"
          );
        };
      };
    })
  ];
}
