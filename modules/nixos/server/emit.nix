{
  config,
  flake,
  lib,
  ...
}:
let
  instances = {
    "emit-prod" = {
      hostAddress = "10.231.10.1";
      localAddress = "10.231.10.2";
      ambientApplication = "1";
      engine = "native";
      apiBase = "https://emit-api.znaniye.xyz";
    };
    "emit-staging" = {
      hostAddress = "10.231.10.3";
      localAddress = "10.231.10.4";
      ambientApplication = "2";
      engine = "native";
      apiBase = "https://emit-api-staging.znaniye.xyz";
    };
    "emit-tipsoft" = {
      apiBase = "http://127.0.0.1:5055";
      hostAddress = "10.231.10.5";
      localAddress = "10.231.10.6";
      ambientApplication = "1";
      engine = "tipsoft";
    };
  };

  instanceHostPorts = lib.listToAttrs (
    lib.imap0 (index: instanceName: {
      name = instanceName;
      value = 9898 + index;
    }) (builtins.attrNames instances)
  );

  instanceHostPostgresPorts = lib.listToAttrs (
    lib.imap0 (index: instanceName: {
      name = instanceName;
      value = 15432 + index;
    }) (builtins.attrNames instances)
  );

  mkContainer =
    name:
    {
      ambientApplication,
      apiBase,
      engine,
      hostAddress,
      localAddress,
      ...
    }:
    {
      privateNetwork = true;
      inherit hostAddress localAddress;

      autoStart = true;
      restartIfChanged = true;

      bindMounts."/run/age-keys.txt" = {
        hostPath = "/home/znaniye/.config/sops/age/keys.txt";
        isReadOnly = true;
      };

      forwardPorts = [
        {
          protocol = "tcp";
          hostPort = instanceHostPorts.${name};
          containerPort = 9999;
        }
        {
          protocol = "tcp";
          hostPort = instanceHostPostgresPorts.${name};
          containerPort = 5432;
        }
      ];

      config =
        { config, ... }:
        {
          imports = [
            flake.inputs.emit.nixosModules.emit
            flake.inputs.sops.nixosModules.sops
          ];

          networking = {
            useHostResolvConf = lib.mkForce false;
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
          };

          sops.defaultSopsFile = ../../../secrets/var.yaml;
          sops.age.keyFile = lib.mkForce "/run/age-keys.txt";

          sops = {
            secrets = {
              "emit-sql-con" = { };
              "emit-user" = { };
              "emit-billing-webhook" = { };
              "emit-pg-con" = { };
              "emit-pg-password" = {
                owner = "postgres";
                group = "postgres";
                mode = "0400";
              };
              "emit_s3_access_key_id" = { };
              "emit_s3_secret_access_key" = { };
              "emit-discord-webhook" = { };
              "emit-discord-signup-webhook-prod" = { };
              "emit-discord-signup-webhook-staging" = { };
              "emit-resend-api-key" = { };
              "emit-stripe-secret-key" = { };
              "emit-stripe-webhook-secret" = { };
            };
            templates =
              let
                commonEnv = ''
                  EMIT_SEFAZ_TPAMB=${ambientApplication}
                  EMIT_ENGINE=${engine}
                  EMIT_DATA_DIR=/var/lib/emit-api
                '';
                signupNotifyUrl =
                  if name == "emit-staging" then
                    config.sops.placeholder."emit-discord-signup-webhook-staging"
                  else
                    config.sops.placeholder."emit-discord-signup-webhook-prod";
                apiEnv =
                  if engine == "native" then
                    ''
                      EMIT_PG_CONNECTION=Host=127.0.0.1;${config.sops.placeholder."emit-pg-con"}
                      EMIT_S3_ENDPOINT=s3.us-east-005.backblazeb2.com
                      EMIT_S3_REGION=us-east-005
                      EMIT_S3_ACCESS_KEY_ID=${config.sops.placeholder."emit_s3_access_key_id"}
                      EMIT_S3_SECRET_ACCESS_KEY=${config.sops.placeholder."emit_s3_secret_access_key"}
                      EMIT_S3_PRIMARY_BUCKET=emit-app
                      EMIT_S3_READ_BUCKETS=emit-app
                      EMIT_S3_FORCE_PATH_STYLE=true
                      EMIT_SIGNUP_NOTIFY_URL=${signupNotifyUrl}
                      EMIT_PUBLIC_URL=https://emit.znaniye.xyz
                      EMIT_RESEND_API_KEY=${config.sops.placeholder."emit-resend-api-key"}
                      EMIT_RESEND_FROM="Emit <mail@emit.znaniye.xyz>"
                      EMIT_STRIPE_SECRET_KEY=${config.sops.placeholder."emit-stripe-secret-key"}
                      EMIT_STRIPE_PURCHASE_NOTIFY_URL=${config.sops.placeholder."emit-billing-webhook"}
                      EMIT_STRIPE_WEBHOOK_SECRET=${config.sops.placeholder."emit-stripe-webhook-secret"}
                    ''
                    + commonEnv
                  else if engine == "tipsoft" then
                    ''
                      EMIT_SQL_CONNECTION=${config.sops.placeholder."emit-sql-con"}
                      EMIT_USUARIO_NOME=${config.sops.placeholder."emit-user"}
                      EMIT_PK_EMITENTE=1
                    ''
                    + commonEnv
                  else
                    (throw "${engine} does not exists.");
              in
              {
                apiEnvFile.content = apiEnv;
              };
          };

          services.emit = {
            enable = true;
            web.apiBase = apiBase;
            openFirewall = lib.mkIf (engine == "tipsoft") false;
            api = {
              bind = lib.mkIf (engine == "tipsoft") "127.0.0.1";
              envFile = "${config.sops.templates.apiEnvFile.path}";
            };
            database = {
              passwordFile = config.sops.secrets.emit-pg-password.path;
            };
          };

          services.nginx.virtualHosts."emit-web".locations = lib.mkIf (engine == "tipsoft") {
            "/api/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.emit.api.port}";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              '';
            };

            "= /runtime-config.js".extraConfig = ''
              return 200 "window.__EMIT_CONFIG__ = { apiBase: \"$scheme://$http_host\" };";
            '';
          };

          networking.firewall.allowedTCPPorts = [
            9999
            5432
          ];
          networking.firewall.allowPing = true;
        };
    };

  mkContainers = lib.mapAttrs mkContainer;
in
{

  options.nixos.server.emit.enable = lib.mkEnableOption "emit config" // {
    default = config.nixos.server.enable;
  };

  config = lib.mkIf config.nixos.server.emit.enable {

    boot.enableContainers = true;
    virtualisation.containers.enable = true;
    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;

    networking = {
      firewall = {
        allowedTCPPorts =
          (builtins.attrValues instanceHostPorts) ++ (builtins.attrValues instanceHostPostgresPorts);
        trustedInterfaces = [ "ve-+" ];
      };

      nat = {
        enable = true;
        internalInterfaces = [ "ve-+" ];
        externalInterface = "end0";
      };
    };

    containers = mkContainers instances;
  };
}
