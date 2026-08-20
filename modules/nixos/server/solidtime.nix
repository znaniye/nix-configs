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
    dependsOn = [
      "solidtime-database"
      "solidtime-gotenberg"
    ];
    environmentFiles = [ config.sops.templates."solidtime-laravel.env".path ];
    extraOptions = appExtraOptions;
    user = "1000:1000";
    volumes = [ "solidtime-storage:/var/www/html/storage" ];
  };
in
{
  config = lib.mkIf cfg.enable {
    services.cloudflared.tunnels."2caba45d-72f1-428d-8263-f6e39c9c626c".ingress.${cfg.domain} =
      lib.mkIf config.nixos.server.cloudflared.enable
        {
          service = "http://localhost:${toString port}";
        };
    sops.secrets = {
      "solidtime-app-key" = { };
      "solidtime-db-password" = { };
      "solidtime-passport-private-key" = { };
      "solidtime-passport-public-key" = { };
    };
    sops.templates."solidtime-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."solidtime-db-password"}
    '';
    sops.templates."solidtime-laravel.env".content = laravelEnv;
    systemd.services = lib.mkMerge [
      {
        solidtime-network = {
          before = map (n: "${backend}-${n}.service") containers;
          path = [ pkgs.podman ];
          script = ''
            podman network exists ${network} \
              || podman network create --disable-dns --subnet ${subnet} --gateway ${gateway} ${network}
          '';
          serviceConfig = {
            RemainAfterExit = true;
            Type = "oneshot";
          };
          wantedBy = [ "multi-user.target" ];
        };
      }
      (lib.genAttrs (map (n: "${backend}-${n}") containers) (_: {
        after = [ "solidtime-network.service" ];
        requires = [ "solidtime-network.service" ];
        serviceConfig.Restart = lib.mkOverride 500 "always";
        serviceConfig.RestartSec = lib.mkOverride 500 "10s";
      }))
    ];
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers = {
      solidtime-app =
        (mkAppContainer {
          AUTO_DB_MIGRATE = "true";
          CONTAINER_MODE = "http";
        })
        // {
          ports = [ "127.0.0.1:${toString port}:8000" ];
        };
      solidtime-database = {
        environment = {
          POSTGRES_DB = "solidtime";
          POSTGRES_USER = "solidtime";
        };
        environmentFiles = [ config.sops.templates."solidtime-db.env".path ];
        extraOptions = [
          "--network=${network}"
          "--ip=${dbIp}"
        ];
        image = "postgres:15";
        volumes = [ "solidtime-db:/var/lib/postgresql/data" ];
      };
      solidtime-gotenberg = {
        extraOptions = [
          "--network=${network}"
          "--ip=${gotenbergIp}"
        ];
        image = "gotenberg/gotenberg:8";
      };
      solidtime-queue = mkAppContainer {
        CONTAINER_MODE = "worker";
        WORKER_COMMAND = "php /var/www/html/artisan queue:work";
      };
      solidtime-scheduler = mkAppContainer {
        CONTAINER_MODE = "scheduler";
      };
    };
    virtualisation.podman.enable = true;
  };
  options.nixos.server.solidtime = {
    domain = lib.mkOption {
      default = "solidtime.znaniye.xyz";
      type = lib.types.str;
    };
    enable = lib.mkEnableOption "self-hosted Solidtime";
    superAdmins = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };
}
