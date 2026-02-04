{ flake, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    flake.inputs.sops.nixosModules.sops
  ];

  nixos = {
    desktop = {
      enable = true;
      wayland.enable = true;
    };
    home.extraModules = {
      home-manager.dev = {
        lua.enable = true;
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

  system.stateVersion = config.system.nixos.release;
}
