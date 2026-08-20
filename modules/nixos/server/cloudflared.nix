{
  config,
  lib,
  ...
}:

{

  config = lib.mkIf config.nixos.server.cloudflared.enable {

    networking.firewall.allowedTCPPorts = [ ];
    services.cloudflared = {
      enable = true;
      tunnels = {
        "2caba45d-72f1-428d-8263-f6e39c9c626c" = {
          credentialsFile = "${config.sops.secrets.cf-credentials.path}";
          default = "http_status:404";
          ingress = {
            "garnix.znaniye.xyz" = {
              service = "http://localhost:80";
            };
            "gitea.znaniye.xyz" = {
              service = "http://localhost:3000";
            };
            "pihole.znaniye.xyz" = {
              service = "http://localhost:8053";
            };
          };
        };
      };

    };
    sops.secrets = {
      "cf-credentials" = {
        format = "json";
        key = "";
        sopsFile = ../../../secrets/credentials-file-cf.json;
      };
    };
  };
  options.nixos.server.cloudflared.enable = lib.mkEnableOption "cloudflared config" // {
    default = config.nixos.server.enable;
  };
}
