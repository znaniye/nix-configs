{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.k3s;

  giteaHost = "192.168.68.111";
  registryEndpoint = "${giteaHost}:3000";
  opsUrl = "http://${giteaHost}:3000/znaniye/ops.git";
  opsBranch = "main";
  gitSecretName = "flux-git-auth";

  ciliumVersion = "1.19.5";
  gatewayApiVersion = "1.4.1";
  envoyGatewayVersion = "1.8.2";

  gatewayApiCrds = pkgs.fetchurl {
    url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v${gatewayApiVersion}/standard-install.yaml";
    hash = "sha256-c7kbd/a+AjqMkslp/GZOW9OxoorqWerJ68kEYHNU2tI=";
  };

  envoyGatewayCrds = pkgs.fetchurl {
    url = "https://github.com/envoyproxy/gateway/releases/download/v${envoyGatewayVersion}/envoy-gateway-crds.yaml";
    hash = "sha256-I/CRPyAKvR18Y0w/ssPrYCHMToS9110ylnEbkzRHKrs=";
  };

  manifests = import ./manifests.nix {
    inherit
      lib
      opsUrl
      opsBranch
      gitSecretName
      ciliumVersion
      ;
  };

  sopsOperatorNamespace = "sops-secrets-operator";
  fluxNamespace = "flux-system";
in
{
  options.nixos.server.k3s = {
    enable = lib.mkEnableOption "k3s cluster (Cilium CNI + Gateway API + Flux GitOps)";

    serverAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://192.168.68.111:6443";
      description = "URL of an existing k3s server to join. null makes this node initialize the cluster (embedded etcd).";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."cluster-age-key" = { };
    sops.secrets."k3s-token" = { };
    sops.secrets."gitea-pat-token" = { };

    sops.templates."k3s-registries.yaml" = {
      path = "/etc/rancher/k3s/registries.yaml";
      content = ''
        mirrors:
          "${registryEndpoint}":
            endpoint:
              - "http://${registryEndpoint}"
        configs:
          "${registryEndpoint}":
            auth:
              username: znaniye
              password: ${config.sops.placeholder."gitea-pat-token"}
      '';
    };

    systemd.services.k3s.restartTriggers = [
      config.sops.templates."k3s-registries.yaml".content
    ];

    services.k3s = {
      enable = true;
      role = "server";
      clusterInit = cfg.serverAddr == null;
      serverAddr = lib.mkIf (cfg.serverAddr != null) cfg.serverAddr;
      tokenFile = config.sops.secrets."k3s-token".path;

      disable = [
        "traefik"
        "servicelb"
      ];

      extraFlags = [
        "--flannel-backend=none"
        "--disable-network-policy"
        "--disable-kube-proxy"
      ];

      autoDeployCharts.flux = {
        repo = "https://fluxcd-community.github.io/helm-charts";
        name = "flux2";
        version = "2.18.4";
        hash = "sha256-Ji8GRuYP/bUP+clE3QpkVcp+ZDWbI3/4ou3WC1kW9Xo=";
        targetNamespace = fluxNamespace;
        createNamespace = true;
      };

      inherit manifests;
    };

    systemd.services.k3s-sops-age-bootstrap = {
      description = "Seed sops-age Secret for sops-secrets-operator";
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = "age-key:${config.sops.secrets."cluster-age-key".path}";
      };
      path = [ config.services.k3s.package ];
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        until k3s kubectl get --raw=/readyz >/dev/null 2>&1; do
          echo "waiting for k3s API..."; sleep 3
        done

        k3s kubectl create namespace ${sopsOperatorNamespace} \
          --dry-run=client -o yaml | k3s kubectl apply -f -

        k3s kubectl -n ${sopsOperatorNamespace} create secret generic sops-age \
          --from-file=keys.txt="$CREDENTIALS_DIRECTORY/age-key" \
          --dry-run=client -o yaml | k3s kubectl apply -f -
      '';
    };

    systemd.services.k3s-flux-git-bootstrap = {
      description = "Seed flux-git-auth Secret (HTTP PAT) for Flux";
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = "git-token:${config.sops.secrets."gitea-pat-token".path}";
      };
      path = [ config.services.k3s.package ];
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        until k3s kubectl get --raw=/readyz >/dev/null 2>&1; do
          echo "waiting for k3s API..."; sleep 3
        done

        k3s kubectl create namespace ${fluxNamespace} \
          --dry-run=client -o yaml | k3s kubectl apply -f -

        password="$(tr -d '\r\n' < "$CREDENTIALS_DIRECTORY/git-token")"

        k3s kubectl -n ${fluxNamespace} delete secret ${gitSecretName} --ignore-not-found >/dev/null 2>&1
        k3s kubectl -n ${fluxNamespace} create secret generic ${gitSecretName} \
          --from-literal=username=znaniye \
          --from-literal=password="$password"
      '';
    };

    systemd.services.k3s-gateway-api-crds = {
      description = "Install Gateway API CRDs (server-side) for Cilium Gateway";
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ config.services.k3s.package ];
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        until k3s kubectl get --raw=/readyz >/dev/null 2>&1; do
          echo "waiting for k3s API..."; sleep 3
        done

        k3s kubectl apply --server-side --force-conflicts -f ${gatewayApiCrds}

        for _ in $(seq 1 10); do
          if k3s kubectl get gatewayclass cilium >/dev/null 2>&1; then
            exit 0
          fi
          sleep 3
        done

        k3s kubectl -n kube-system rollout restart deployment/cilium-operator || true
      '';
    };

    systemd.services.k3s-envoy-gateway-crds = {
      description = "Install Envoy Gateway CRDs (server-side)";
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ config.services.k3s.package ];
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        until k3s kubectl get --raw=/readyz >/dev/null 2>&1; do
          echo "waiting for k3s API..."; sleep 3
        done

        k3s kubectl apply --server-side --force-conflicts -f ${envoyGatewayCrds}
      '';
    };
  };
}
