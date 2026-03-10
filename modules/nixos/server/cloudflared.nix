{
  config,
  lib,
  ...
}:

{

  options.nixos.server.cloudflared.enable = lib.mkEnableOption "cloudflared config" // {
    default = config.nixos.server.enable;
  };

  config = lib.mkIf config.nixos.server.cloudflared.enable {

    sops.secrets = {
      "cf-credentials" = {
        format = "json";
        key = "";
        sopsFile = ../../../secrets/credentials-file-cf.json;
      };
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "2caba45d-72f1-428d-8263-f6e39c9c626c" = {
          credentialsFile = "${config.sops.secrets.cf-credentials.path}";
          ingress = {
            "gitea.znaniye.xyz" = {
              service = "http://localhost:3000";
            };
            "emit.znaniye.xyz" = {
              service = "http://10.231.10.4:9999";
            };
            "emit-api.znaniye.xyz" = {
              service = "http://10.231.10.4:5055";
            };
          };
          default = "http_status:404";
        };
      };

    };

    networking.firewall.allowedTCPPorts = [ ];
  };
}
