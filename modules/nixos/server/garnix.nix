{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.garnix;
  hostname = "garnix.znaniye.xyz";
in
{
  imports = [
    "${flake.inputs.garnix-ci}/nix/modules/garnix-server.nix"
  ];

  options.nixos.server.garnix = {
    enable = lib.mkEnableOption "garnix self-host" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    _module.args = {
      flakeInputs = flake.inputs.garnix-ci.inputs;
      flakePackages = flake.inputs.garnix-ci.packages.${pkgs.system};
    };

    # nix.distributedBuilds is asserted false by garnix-server when remoteBuilders
    # is empty. tortinha runs its own remote-builder module (cache.freedom.ind.br),
    # so flip it back on.
    nix.distributedBuilds = lib.mkForce true;
    nix.daemonIOSchedPriority = lib.mkForce 7;

    # garnix-server enables programs.ssh.startAgent for remote-builder ssh. We
    # have no remoteBuilders.hosts set, and golf's gnome gcr-ssh-agent owns the
    # SSH socket. Force startAgent off to avoid the assertion conflict.
    programs.ssh.startAgent = lib.mkForce false;

    # Local OpenSearch is plain HTTP on :9200 (security plugin off). Point the
    # fluent-bit shipper there instead of the upstream 443/TLS default. This
    # also brings up the build-logs HTTP input on :8888 — the backend POSTs
    # build logs there, and a refused connection (shipper down) otherwise
    # propagates as a build failure.
    garnix.fluent-bit.opensearch.port = 9200;
    garnix.fluent-bit.opensearch.tls = false;

    sops.secrets =
      let
        garnixOwned = {
          owner = "root";
          group = "garnix";
          mode = "0440";
        };
      in
      {
        "garnix-database-password" = {
          owner = "postgres";
          group = "postgres";
          mode = "0440";
        };
        "garnix-opensearch-password" = garnixOwned;
        "garnix-github-webhook-secret" = garnixOwned;
        "garnix-github-client-secret" = garnixOwned;
        "garnix-github-client-id" = garnixOwned;
        "garnix-github-app-id" = garnixOwned;
        "garnix-github-app-pk" = garnixOwned;
        "garnix-jwt-key" = garnixOwned;
        "garnix-repo-secrets-key" = garnixOwned;
        "garnix-repo-secrets-key-pub" = garnixOwned;
        "garnix-action-runner-ssh" = garnixOwned;
      };

    services.garnixServer = {
      enable = true;
      inherit hostname;
      url = "https://${hostname}";
      adminGithubLogin = "znaniye";
      githubAppName = "garnix-znaniye";

      database = {
        host = "127.0.0.1";
        port = 5432;
        user = "garnix";
        name = "garnix";
        ssl.mode = "disable";
      };

      opensearch = {
        url = "http://127.0.0.1:9200/_msearch";
        host = "127.0.0.1";
        username = "garnix";
      };

      s3Cache.enable = false;
      remoteBuilders.hosts = [ ];

      actionRunner.host = "127.0.0.1";

      secrets = {
        databasePasswordPath = config.sops.secrets."garnix-database-password".path;
        opensearchCredentialPath = config.sops.secrets."garnix-opensearch-password".path;
        githubWebhookSecretPath = config.sops.secrets."garnix-github-webhook-secret".path;
        githubClientSecretPath = config.sops.secrets."garnix-github-client-secret".path;
        githubClientIdPath = config.sops.secrets."garnix-github-client-id".path;
        githubAppIdPath = config.sops.secrets."garnix-github-app-id".path;
        githubAppPkPath = config.sops.secrets."garnix-github-app-pk".path;
        jwtKeyPath = config.sops.secrets."garnix-jwt-key".path;
        repoSecretsKeyPath = config.sops.secrets."garnix-repo-secrets-key".path;
        repoSecretsPubKeyPath = config.sops.secrets."garnix-repo-secrets-key-pub".path;
        actionRunnerSshPath = config.sops.secrets."garnix-action-runner-ssh".path;
      };
    };

    garnix.actionRunner.authorizedKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2DPx198YXU9f0dCAwWhPBIVswQ/H9KVuaXe19Brhme garnix-action-runner@golf";

    services.nginx.virtualHosts.${hostname} = {
      forceSSL = lib.mkForce false;
      enableACME = lib.mkForce false;
    };

    services.postgresql = {
      enable = true;
      package = lib.mkForce pkgs.postgresql_18;
      ensureDatabases = [ "garnix" ];
      ensureUsers = [
        {
          name = "garnix";
          ensureDBOwnership = true;
        }
      ];
      # Backend uses postgresql-typed which speaks only md5/cleartext auth
      # (no SASL/SCRAM). Force md5 for the garnix TCP entries.
      # dev/emit-app.nix's authentication block sets it at mkOverride 10,
      # which discards default-priority strings, so match priority to merge.
      authentication = lib.mkOverride 10 ''
        host garnix garnix 127.0.0.1/32 md5
        host garnix garnix ::1/128     md5
      '';
    };

    systemd.services.garnix-postgres-password-sync = {
      description = "Sync garnix postgres role password from sops secret";
      after = [ "postgresql-setup.service" ];
      requires = [ "postgresql-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      before = [ "garnixServer.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        LoadCredential = "password:${config.sops.secrets."garnix-database-password".path}";
      };
      script = ''
        PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/password")
        ${config.services.postgresql.package}/bin/psql -tAc "SET password_encryption = 'md5'; ALTER USER garnix WITH PASSWORD '$PASSWORD';"
      '';
    };

    services.opensearch = {
      enable = true;
      settings = {
        "network.host" = "127.0.0.1";
        "discovery.type" = "single-node";
        "plugins.security.disabled" = true;
      };
      extraJavaOptions = [
        "-Xms512m"
        "-Xmx512m"
      ];
    };
  };
}
