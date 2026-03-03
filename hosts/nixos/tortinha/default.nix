{
  config,
  flake,
  lib,
  nixos-raspberrypi,
  modulesPath,
  ...
}:
{

  imports = [
    nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
    #nixos-raspberrypi.nixosModules.sd-image
    nixos-raspberrypi.lib.inject-overlays
    nixos-raspberrypi.nixosModules.trusted-nix-caches
    flake.inputs.disko.nixosModules.disko
    flake.inputs.emit.nixosModules.emit
    ./disko.nix
    (lib.mkAliasOptionModuleMD [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
  ];

  disabledModules = [
    (modulesPath + "/rename.nix")
  ];

  nixos.server.enable = true;
  nixos.desktop = {
    sops.enable = true;
    tailscale.enable = true;
  };
  nixos.home.extraModules.home-manager.dev.enable = false;

  programs.zsh.enable = true;

  hardware.raspberry-pi.config = {
    all = {
      base-dt-params = {
        pciex1 = {
          enable = true;
          value = "on";
        };
        pciex1_gen = {
          enable = true;
          value = "3";
        };
      };
    };
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  sops.secrets.emit-sql-con = { };
  sops.secrets.emit-user = { };
  sops.secrets.emit-pg-con = { };
  sops.secrets.emit_s3_access_key_id = { };
  sops.secrets.emit_s3_secret_access_key = { };

  sops.templates = {
    apiEnvFile.content = ''
      EMIT_ENGINE=tipsoft
      EMIT_SQL_CONNECTION=${config.sops.placeholder.emit-sql-con}
      EMIT_USUARIO_NOME=${config.sops.placeholder.emit-user}
      EMIT_PK_EMITENTE=1
      EMIT_SEFAZ_TPAMB=1
      EMIT_SEFAZ_TLS_DEBUG=1
    '';
    apiShadowWorkerEnvFile.content = ''
      EMIT_ENGINE=native
      EMIT_PG_CONNECTION=${config.sops.placeholder.emit-pg-con}
      EMIT_SEFAZ_TPAMB=2
      EMIT_S3_ENDPOINT=s3.us-east-005.backblazeb2.com 
      EMIT_S3_REGION=us-east-005
      EMIT_S3_PRIMARY_BUCKET=emit-app
      EMIT_S3_READ_BUCKETS=emit-app
      EMIT_S3_ACCESS_KEY_ID=${config.sops.placeholder.emit-pg-con}
      EMIT_S3_SECRET_ACCESS_KEY=${config.sops.placeholder.emit-pg-con}
    '';
  };

  services.emit = {
    enable = true;
    api.envFile = "${config.sops.templates.apiEnvFile.path}";
    api-shadow-worker.envFile = "${config.sops.templates.apiShadowWorkerEnvFile.path}";
  };

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = config.system.nixos.release;
}
