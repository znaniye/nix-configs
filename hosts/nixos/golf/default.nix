{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nixos = {
    desktop = {
      enable = true;
      virtualization.enable = true;
      wayland.enable = true;
    };
    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
        dotnet.enable = true;
      };
    };
  };

  networking.firewall.enable = false;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  services.logind.lidSwitchExternalPower = "ignore";

  services.openssh.settings.PermitRootLogin = "no";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.hardware.deepcool-digital-linux.enable = true;

  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    enableTCPIP = true;

    settings = {
      listen_addresses = "*";
      port = 5432;
      password_encryption = "scram-sha-256";
    };

    ensureDatabases = [ "emit_app" ];
    ensureUsers = [
      {
        name = "emit_app";
        ensureDBOwnership = true;
      }
    ];

    authentication = lib.mkOverride 10 (''
      # TYPE  DATABASE  USER      ADDRESS           METHOD
      local   all       all                         peer
      host  emit_app  emit_app  127.0.0.1/32  scram-sha-256
      host  emit_app  emit_app  ::1/128       scram-sha-256
    '');
  };

  system.stateVersion = config.system.nixos.release;
}
