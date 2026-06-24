{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.solidtime;
  backend = config.virtualisation.oci-containers.backend;

  image = "solidtime/solidtime:latest";
  network = "solidtime";
  subnet = "10.123.0.0/24";
  gateway = "10.123.0.1";
  dbIp = "10.123.0.10";
  gotenbergIp = "10.123.0.11";
  dbHost = "solidtime-database";
  gotenbergHost = "solidtime-gotenberg";
  port = 8000;

  containers = [
    "solidtime-app"
    "solidtime-scheduler"
    "solidtime-queue"
    "solidtime-database"
    "solidtime-gotenberg"
  ];

  laravelEnv = ''
    APP_NAME=solidtime
    VITE_APP_NAME=solidtime
    APP_ENV=production
    APP_DEBUG=false
    APP_URL=https://${cfg.domain}
    APP_FORCE_HTTPS=true
    APP_ENABLE_REGISTRATION=true
    TRUSTED_PROXIES=*
    SUPER_ADMINS=${lib.concatStringsSep "," cfg.superAdmins}
    PAGINATION_PER_PAGE_DEFAULT=500
    OCTANE_SERVER=frankenphp
    LOG_CHANNEL=stderr_daily
    LOG_LEVEL=warning
    DB_CONNECTION=pgsql
    DB_HOST=${dbHost}
    DB_PORT=5432
    DB_SSLMODE=prefer
    DB_DATABASE=solidtime
    DB_USERNAME=solidtime
    DB_PASSWORD=${config.sops.placeholder."solidtime-db-password"}
    QUEUE_CONNECTION=database
    FILESYSTEM_DISK=local
    PUBLIC_FILESYSTEM_DISK=public
    MAIL_MAILER=log
    MAIL_FROM_ADDRESS=no-reply@${cfg.domain}
    MAIL_FROM_NAME=solidtime
    GOTENBERG_URL=http://${gotenbergHost}:3000
    APP_KEY=${config.sops.placeholder."solidtime-app-key"}
    PASSPORT_PRIVATE_KEY=${config.sops.placeholder."solidtime-passport-private-key"}
    PASSPORT_PUBLIC_KEY=${config.sops.placeholder."solidtime-passport-public-key"}
  '';

  appExtraOptions = [
    "--network=${network}"
    "--add-host=${dbHost}:${dbIp}"
    "--add-host=${gotenbergHost}:${gotenbergIp}"
  ];

  mkAppContainer = environment: {
    inherit image environment;
    user = "1000:1000";
    dependsOn = [
      "solidtime-database"
      "solidtime-gotenberg"
    ];
    volumes = [ "solidtime-storage:/var/www/html/storage" ];
    environmentFiles = [ config.sops.templates."solidtime-laravel.env".path ];
    extraOptions = appExtraOptions;
  };
in
{
  options.nixos.server.solidtime = {
    enable = lib.mkEnableOption "self-hosted Solidtime";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "solidtime.znaniye.xyz";
    };

    superAdmins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    sops.secrets = {
      "solidtime-app-key" = { };
      "solidtime-passport-private-key" = { };
      "solidtime-passport-public-key" = { };
      "solidtime-db-password" = { };
    };

    sops.templates."solidtime-laravel.env".content = laravelEnv;
    sops.templates."solidtime-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."solidtime-db-password"}
    '';

    virtualisation.oci-containers.containers = {
      solidtime-app = (mkAppContainer {
        CONTAINER_MODE = "http";
        AUTO_DB_MIGRATE = "true";
      }) // {
        ports = [ "127.0.0.1:${toString port}:8000" ];
      };

      solidtime-scheduler = mkAppContainer {
        CONTAINER_MODE = "scheduler";
      };

      solidtime-queue = mkAppContainer {
        CONTAINER_MODE = "worker";
        WORKER_COMMAND = "php /var/www/html/artisan queue:work";
      };

      solidtime-database = {
        image = "postgres:15";
        volumes = [ "solidtime-db:/var/lib/postgresql/data" ];
        environment = {
          POSTGRES_DB = "solidtime";
          POSTGRES_USER = "solidtime";
        };
        environmentFiles = [ config.sops.templates."solidtime-db.env".path ];
        extraOptions = [
          "--network=${network}"
          "--ip=${dbIp}"
        ];
      };

      solidtime-gotenberg = {
        image = "gotenberg/gotenberg:8";
        extraOptions = [
          "--network=${network}"
          "--ip=${gotenbergIp}"
        ];
      };
    };

    systemd.services = lib.mkMerge [
      {
        solidtime-network = {
          wantedBy = [ "multi-user.target" ];
          before = map (n: "${backend}-${n}.service") containers;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ pkgs.podman ];
          script = ''
            podman network exists ${network} \
              || podman network create --disable-dns --subnet ${subnet} --gateway ${gateway} ${network}
          '';
        };
      }
      (lib.genAttrs (map (n: "${backend}-${n}") containers) (_: {
        after = [ "solidtime-network.service" ];
        requires = [ "solidtime-network.service" ];
        serviceConfig.Restart = lib.mkOverride 500 "always";
        serviceConfig.RestartSec = lib.mkOverride 500 "10s";
      }))
    ];

    services.cloudflared.tunnels."2caba45d-72f1-428d-8263-f6e39c9c626c".ingress.${cfg.domain} =
      lib.mkIf config.nixos.server.cloudflared.enable {
        service = "http://localhost:${toString port}";
      };
  };
}
