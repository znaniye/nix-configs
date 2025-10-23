{ config, lib, ... }:

{
  options.nixos.desktop.wireguard.enable = lib.mkEnableOption "wireguard config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.wireguard.enable {

    networking.wireguard = {
      useNetworkd = false;

      interfaces = {
        wg0 = {
          ips = [ "192.168.240.8/32" ];

          privateKeyFile = config.sops.secrets.wireguard-private-key.path;

          peers = [
            {
              publicKey = "7poZW/qGM9HyZuKaA7ryP+EEtuK6b4E+G2sMcbNr6iM=";
              allowedIPs = [
                "192.168.0.0/23"
                "192.168.150.0/24"
              ];
              endpoint = "hep09fmme67.sn.mynetname.net:13231";
              persistentKeepalive = 10;
              dynamicEndpointRefreshSeconds = 30;
            }
          ];

          postSetup = ''
            resolvectl dns    wg0 192.168.0.233
            resolvectl domain wg0 "~intranet.freedom.ind.br"
            resolvectl dnssec wg0 false
          '';
        };
      };
    };

  };
}
