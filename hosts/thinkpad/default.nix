{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./i3.nix
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings.trusted-users = [ "znaniye" ];
  };

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
    hostName = "felix";
    networkmanager.enable = true;
  };

  services.logind.lidSwitchExternalPower = "ignore";
  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  console.keyMap = "br-abnt2";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  services.blueman.enable = true;

  services.printing = {
    enable = true;
    drivers = [
      pkgs.epson-escpr
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true; # IPv4
    nssmdns6 = true; # IPv6
    openFirewall = true;
  };

  programs.thunar.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.devmon.enable = true;

  # location = {
  #   latitude = -19.92;
  #   longitude = -43.94;
  # };

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

  # services.geoclue2 = {
  #   enable = true;
  #   appConfig.redshift.isAllowed = true;
  # };

  services.tailscale.enable = true;

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

  security.rtkit.enable = true;

  #services.pulseaudio.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.zsh.enable = true;

  virtualisation.docker = {
    enable = true;
  };

  users = {
    users.znaniye = {
      isNormalUser = true;
      description = "znaniye";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
      ];
    };
    defaultUserShell = pkgs.zsh;
  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    tor
    cups-filters
    udiskie
    tailscale
  ];

  system.stateVersion = "24.11";
}
