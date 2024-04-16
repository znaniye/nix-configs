{pkgs, ...}: {
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
  };

  services.printing = {
    enable = true;
    drivers = [pkgs.hplipWithPlugin];
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

  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "pt_BR.UTF-8";
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

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

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
      extraGroups = ["networkmanager" "wheel" "docker"];
    };
    defaultUserShell = pkgs.zsh;
  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    nixfmt
    git
    vim
  ];

  system.stateVersion = "23.11";
}
