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
  # Strip an optional ":port" the same way garnix-server does, so the ssh
  # Match block below targets the bare host.
  actionRunnerHostName = lib.head (lib.splitString ":" cfg.actionRunnerHost);
in
{
  imports = [
    "${flake.inputs.garnix-ci}/nix/modules/garnix-server.nix"
  ];

  options.nixos.server.garnix = {
    enable = lib.mkEnableOption "garnix self-host" // {
      default = false;
    };

    localActionRunner = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run the garnix action-runner (krun/KVM microVMs) on this host. Set to
        false when the coordinator offloads actions to a runner on another host
        (e.g. a low-RAM aarch64 box delegating to an x86_64 builder). When
        false, the local runner service is disabled and only the ssh client
        config needed to reach the remote runner is emitted.
      '';
    };

    actionRunnerHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Host the backend SSHes into (as user action-runner) to execute garnix
        actions. Defaults to loopback (runner co-located with the coordinator).
        Accepts "host" or "host:port".
      '';
    };

    remoteBuilders = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      description = ''
        Remote Nix builders, passed straight to
        services.garnixServer.remoteBuilders.hosts. When non-empty the
        coordinator sets max-jobs=0 and offloads all realisation to these
        builders.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    _module.args = {
      flakeInputs = flake.inputs.garnix-ci.inputs;
      flakePackages = flake.inputs.garnix-ci.packages.${pkgs.system};
    };

    # Both garnix-server and our nixos.nix.remote-builders module define
    # nix.distributedBuilds; force it on to resolve the merge conflict.
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
      remoteBuilders.hosts = cfg.remoteBuilders;

      actionRunner.host = cfg.actionRunnerHost;

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
        # Reuse the action-runner key as the build-offload key: the backend uses
        # one identity to reach golf for both actions (user action-runner) and
        # remote builds (user nixremote). Required iff remoteBuilders != [].
        remoteBuilderSshPath = config.sops.secrets."garnix-action-runner-ssh".path;
      };
    };

    systemd.services.garnixServer.environment.GARNIX_BUILD_TIMEOUT_MINUTES = "600";

    # Local runner: authorize the coordinator's key on the action-runner user.
    # garnix-server also emits the ssh client Match block (gated on
    # garnix.actionRunner.enable) so the backend can reach it.
    garnix.actionRunner.authorizedKey = lib.mkIf cfg.localActionRunner "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2DPx198YXU9f0dCAwWhPBIVswQ/H9KVuaXe19Brhme garnix-action-runner@golf";

    # Remote runner: don't build/run the krun stack locally (would force a heavy
    # aarch64 libkrun/crun build on a Pi). Disabling it also drops the ssh client
    # Match block garnix-server emits, so re-add it here for the remote host.
    garnix.actionRunner.enable = lib.mkIf (!cfg.localActionRunner) (lib.mkForce false);
    programs.ssh.extraConfig = lib.mkIf (!cfg.localActionRunner) (
      lib.mkAfter ''
        Match host ${actionRunnerHostName} user action-runner
           StrictHostKeyChecking accept-new
           UserKnownHostsFile /var/lib/garnix/known_hosts
      ''
    );

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
