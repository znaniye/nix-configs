{ config, ... }:
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
  };

  networking.firewall.enable = false;

  boot = {
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

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.hardware.deepcool-digital-linux.enable = true;

  programs.direnv.enable = true;

  system.stateVersion = config.system.nixos.release;
}
