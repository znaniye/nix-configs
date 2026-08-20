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
    hash = "sha256-c7kbd/a+AjqMkslp/GZOW9OxoorqWerJ68kEYHNU2tI=";
    url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v${gatewayApiVersion}/standard-install.yaml";
  };

  envoyGatewayCrds = pkgs.fetchurl {
    hash = "sha256-I/CRPyAKvR18Y0w/ssPrYCHMToS9110ylnEbkzRHKrs=";
    url = "https://github.com/envoyproxy/gateway/releases/download/v${envoyGatewayVersion}/envoy-gateway-crds.yaml";
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
  config = lib.mkIf cfg.enable {
    services.k3s = {
      inherit manifests;
      autoDeployCharts.flux = {
        createNamespace = true;
        hash = "sha256-Ji8GRuYP/bUP+clE3QpkVcp+ZDWbI3/4ou3WC1kW9Xo=";
        name = "flux2";
        repo = "https://fluxcd-community.github.io/helm-charts";
        targetNamespace = fluxNamespace;
        version = "2.18.4";
      };
      clusterInit = cfg.serverAddr == null;
      disable = [
        "traefik"
        "servicelb"
      ];
      enable = true;
      extraFlags = [
        "--flannel-backend=none"
        "--disable-network-policy"
        "--disable-kube-proxy"
      ];
      role = "server";
      serverAddr = lib.mkIf (cfg.serverAddr != null) cfg.serverAddr;
      tokenFile = config.sops.secrets."k3s-token".path;
    };
    sops.secrets."cluster-age-key" = { };
    sops.secrets."gitea-pat-token" = { };
    sops.secrets."k3s-token" = { };
    sops.templates."k3s-registries.yaml" = {
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
      path = "/etc/rancher/k3s/registries.yaml";
    };
    systemd.services.k3s.restartTriggers = [
      config.sops.templates."k3s-registries.yaml".content
    ];
    systemd.services.k3s-envoy-gateway-crds = {
      after = [ "k3s.service" ];
      description = "Install Envoy Gateway CRDs (server-side)";
      path = [ config.services.k3s.package ];
      requires = [ "k3s.service" ];
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        until k3s kubectl get --raw=/readyz >/dev/null 2>&1; do
          echo "waiting for k3s API..."; sleep 3
        done

        k3s kubectl apply --server-side --force-conflicts -f ${envoyGatewayCrds}
      '';
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.k3s-flux-git-bootstrap = {
      after = [ "k3s.service" ];
      description = "Seed flux-git-auth Secret (HTTP PAT) for Flux";
      path = [ config.services.k3s.package ];
      requires = [ "k3s.service" ];
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
      serviceConfig = {
        LoadCredential = "git-token:${config.sops.secrets."gitea-pat-token".path}";
        RemainAfterExit = true;
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.k3s-gateway-api-crds = {
      after = [ "k3s.service" ];
      description = "Install Gateway API CRDs (server-side) for Cilium Gateway";
      path = [ config.services.k3s.package ];
      requires = [ "k3s.service" ];
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
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.k3s-sops-age-bootstrap = {
      after = [ "k3s.service" ];
      description = "Seed sops-age Secret for sops-secrets-operator";
      path = [ config.services.k3s.package ];
      requires = [ "k3s.service" ];
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
      serviceConfig = {
        LoadCredential = "age-key:${config.sops.secrets."cluster-age-key".path}";
        RemainAfterExit = true;
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
  options.nixos.server.k3s = {
    enable = lib.mkEnableOption "k3s cluster (Cilium CNI + Gateway API + Flux GitOps)";

    serverAddr = lib.mkOption {
      default = null;
      description = "URL of an existing k3s server to join. null makes this node initialize the cluster (embedded etcd).";
      example = "https://192.168.68.111:6443";
      type = lib.types.nullOr lib.types.str;
    };
  };
}
