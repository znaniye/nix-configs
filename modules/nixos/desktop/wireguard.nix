{ config, lib, ... }:
let
  cfg = config.nixos.desktop.wireguard;
  isConfigured = cfg.address != null && cfg.privateKeySecretName != null;
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.address != null;
            message = "Set nixos.desktop.wireguard.address for host ${config.networking.hostName}.";
          }
          {
            assertion = cfg.privateKeySecretName != null;
            message = "Set nixos.desktop.wireguard.privateKeySecretName for host ${config.networking.hostName}.";
          }
        ];
      }

      (lib.mkIf isConfigured {
        networking.wireguard = {
          interfaces = {
            wg0 = {
              ips = [ cfg.address ];
              peers = [
                {
                  allowedIPs = [
                    "192.168.0.0/23"
                    "192.168.150.0/24"
                    "192.168.7.0/24"
                  ];
                  dynamicEndpointRefreshSeconds = 30;
                  endpoint = "hep09fmme67.sn.mynetname.net:13231";
                  persistentKeepalive = 10;
                  publicKey = "7poZW/qGM9HyZuKaA7ryP+EEtuK6b4E+G2sMcbNr6iM=";
                }
              ];
              postSetup = ''
                resolvectl dns    wg0 192.168.0.240
                #resolvectl dns    wg0 192.168.0.233
                resolvectl domain wg0 "~intranet.freedom.ind.br"
                resolvectl dnssec wg0 false
              '';
              privateKeyFile = config.sops.secrets.${cfg.privateKeySecretName}.path;
            };
          };
          useNetworkd = false;
        };
        sops.secrets.${cfg.privateKeySecretName} = { };
      })
    ]
  );
  options.nixos.desktop.wireguard = {
    address = lib.mkOption {
      default = null;
      description = "WireGuard address assigned to this host.";
      type = lib.types.nullOr lib.types.str;
    };
    enable = lib.mkEnableOption "wireguard config" // {
      default = config.nixos.desktop.enable;
    };
    privateKeySecretName = lib.mkOption {
      default = null;
      description = "Name of the SOPS secret that stores this host WireGuard private key.";
      type = lib.types.nullOr lib.types.str;
    };
  };
}
