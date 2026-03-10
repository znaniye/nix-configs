{
  flake,
  config,
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
      apiBase = "https://127.0.0.1:5055";
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

  mkContainer =
    name:
    {
      apiBase,
      hostAddress,
      localAddress,
      ambientApplication,
      engine,
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
      ];

      config =
        { config, ... }:
        {
          imports = [
            flake.inputs.sops.nixosModules.sops
            flake.inputs.emit.nixosModules.emit
          ];

          sops.defaultSopsFile = ../../../secrets/var.yaml;
          sops.age.keyFile = lib.mkForce "/run/age-keys.txt";

          sops = {
            secrets = {
              "emit-sql-con" = { };
              "emit-user" = { };
              "emit-pg-con" = { };
              "emit-pg-password" = {
                owner = "postgres";
                group = "postgres";
                mode = "0400";
              };
              "emit_s3_access_key_id" = { };
              "emit_s3_secret_access_key" = { };
              "emit-shadow-pg-con" = { };
              "emit-shadow-user-id" = { };
              "emit-discord-webhook" = { };
              "emit-discord-signup-webhook-prod" = { };
              "emit-discord-signup-webhook-staging" = { };
            };
            templates =
              let
                commonEnv = ''
                  EMIT_SEFAZ_TPAMB=${ambientApplication}
                  EMIT_ENGINE=${engine}
                  EMIT_SHADOW_NOTIFY_XML_DIFF=1
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
                      EMIT_RESEND_API_KEY=re_e44Wz1rN_3uERuLbNPageKuL1yqhDEKyb
                    ''
                    + commonEnv
                  else if engine == "tipsoft" then
                    ''
                      EMIT_SHADOW_ENABLED=true
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
                apiShadowWorkerEnvFile.content = ''
                  EMIT_SHADOW_ENABLED=true
                  EMIT_SHADOW_PG_CONNECTION=${config.sops.placeholder."emit-shadow-pg-con"}
                  EMIT_SHADOW_USER_ID=${config.sops.placeholder."emit-shadow-user-id"}
                  EMIT_ENGINE=native
                  EMIT_SEFAZ_TPAMB=2
                  EMIT_SHADOW_S3_DISABLED=1
                  EMIT_SHADOW_NOTIFY_URL=${config.sops.placeholder."emit-discord-webhook"}
                  EMIT_SHADOW_NOTIFY_XML_DIFF=1
                  EMIT_DATA_DIR=/var/lib/emit-api
                '';
              };
          };

          services.emit = {
            enable = true;
            web.apiBase = apiBase;
            api = {
              envFile = "${config.sops.templates.apiEnvFile.path}";
              shadowWorker = lib.mkIf (engine == "tipsoft") {
                enable = true;
                envFile = "${config.sops.templates.apiShadowWorkerEnvFile.path}";
              };
            };
            database = {
              passwordFile = config.sops.secrets.emit-pg-password.path;
              shadowPasswordFile = config.sops.secrets.emit-pg-password.path;
            };
          };

          networking.firewall.allowedTCPPorts = [ 9999 ];
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

    networking.firewall.allowedTCPPorts = builtins.attrValues instanceHostPorts;

    containers = mkContainers instances;
  };
}
