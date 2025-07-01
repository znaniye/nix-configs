{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixos.desktop.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    networkmanager.enable = true;
  };

  services.logind.lidSwitchExternalPower = "ignore";

  #console.keyMap = "br-abnt2";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  services.blueman.enable = true;

  # services.printing = {
  #   enable = true;
  #   drivers = [
  #     pkgs.epson-escpr
  #   ];
  # };
  #
  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true; # IPv4
  #   nssmdns6 = true; # IPv6
  #   openFirewall = true;
  # };

  # programs.thunar.enable = true;
  # services.gvfs.enable = true;
  # services.udisks2.enable = true;
  # services.devmon.enable = true;

  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = "-23.5505";
    longitude = "-46.6333";
    temperature = {
      day = 5500;
      night = 2700;
    };
    brightness = {
      day = "1";
      night = "0.8";
    };
  };

  services.tor = {
    enable = true;
    client = {
      enable = true;
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    bluetooth = {
      enable = true;
      package = pkgs.bluez;
    };
  };

  #security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  system.stateVersion = "24.11";
}
