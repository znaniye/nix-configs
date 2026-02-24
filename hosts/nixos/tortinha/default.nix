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

  sops.templates.emitEnvFile.content = ''
    EMIT_ENGINE=tipsoft
    EMIT_PG_CONNECTION=${config.sops.placeholder.emit-pg-con}
    EMIT_SQL_CONNECTION=${config.sops.placeholder.emit-sql-con}
    EMIT_USUARIO_NOME=${config.sops.placeholder.emit-user}
    EMIT_PK_EMITENTE=1
    EMIT_SEFAZ_TPAMB=2
    EMIT_SEFAZ_TLS_DEBUG=1
  '';

  services.emit = {
    enable = true;
    envFile = "${config.sops.templates.emitEnvFile.path}";
  };

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = config.system.nixos.release;
}
