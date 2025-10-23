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
          ips = [ "192.168.150.2/24" ];

          privateKeyFile = config.sops.secrets.wireguard-private-key.path;

          peers = [
            {
              publicKey = "cFeqza8ykggGgNSRJ3eI67v6EOzuOukVfqtD4n6r/2w=";
              allowedIPs = [ "192.168.0.0/24" ];
              endpoint = "8aff0aba023e.sn.mynetname.net:13231";
              persistentKeepalive = 25;
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
