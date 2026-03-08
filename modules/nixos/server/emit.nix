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
    };
    "emit-dev" = {
      hostAddress = "10.231.10.3";
      localAddress = "10.231.10.4";
    };
  };

  mkContainer =
    name:
    {
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
              "emit-shadow-pg-con" = { };
              "emit-shadow-user-id" = { };
              "emit-discord-webhook" = { };
            };
            templates = {
              apiEnvFile.content = ''
                EMIT_ENGINE=tipsoft
                EMIT_SHADOW_ENABLED=true
                EMIT_SQL_CONNECTION=${config.sops.placeholder."emit-sql-con"}
                EMIT_USUARIO_NOME=${config.sops.placeholder."emit-user"}
                EMIT_PK_EMITENTE=1
                EMIT_SEFAZ_TPAMB=1
                EMIT_SEFAZ_TLS_DEBUG=1
                EMIT_SHADOW_NOTIFY_XML_DIFF=1
                EMIT_DATA_DIR=/var/lib/emit-api
              '';
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
            api = {
              envFile = "${config.sops.templates.apiEnvFile.path}";
              shadowWorker = {
                enable = true;
                envFile = "${config.sops.templates.apiShadowWorkerEnvFile.path}";
              };
            };
          };
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

    containers = mkContainers instances;
  };
}
