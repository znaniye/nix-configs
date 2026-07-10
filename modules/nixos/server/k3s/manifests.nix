{
  lib,
  opsUrl,
  opsBranch,
  gitSecretName,
  ciliumVersion,
}:
{
  cilium.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "cilium";
      namespace = "kube-system";
    };
    spec = {
      bootstrap = true;
      repo = "https://helm.cilium.io";
      chart = "cilium";
      version = ciliumVersion;
      targetNamespace = "kube-system";
      valuesContent = ''
        kubeProxyReplacement: true
        k8sServiceHost: 127.0.0.1
        k8sServicePort: 6443
        gatewayAPI:
          enabled: true
        ipam:
          mode: kubernetes
        operator:
          replicas: 1
        hubble:
          enabled: true
          relay:
            enabled: true
          ui:
            enabled: true
      '';
    };
  };

  flux-git-repository.content = {
    apiVersion = "source.toolkit.fluxcd.io/v1";
    kind = "GitRepository";
    metadata = {
      name = "ops";
      namespace = "flux-system";
    };
    spec = {
      interval = "1m";
      url = opsUrl;
      ref.branch = opsBranch;
      secretRef.name = gitSecretName;
    };
  };

  flux-kustomization.content = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1";
    kind = "Kustomization";
    metadata = {
      name = "flux-system";
      namespace = "flux-system";
    };
    spec = {
      interval = "10m";
      path = "./clusters/prod";
      prune = true;
      sourceRef = {
        kind = "GitRepository";
        name = "ops";
      };
    };
  };
}
