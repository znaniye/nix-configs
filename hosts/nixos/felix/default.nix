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
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  services.logind.lidSwitchExternalPower = "ignore";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

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

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  system.stateVersion = "24.11";
}
