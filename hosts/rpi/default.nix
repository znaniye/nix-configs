{
  pkgs,
  nixos-raspberrypi,
  ...
}:
{

  imports =
    with nixos-raspberrypi.nixosModules;
    [
      # Hardware configuration
      raspberry-pi-5.base
      raspberry-pi-5.display-vc4
      ./pi5-configtxt.nix
    ]
    ++ [ ./disko-nvme-zfs.nix ];

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings.trusted-users = [ "nixos" ];
  };

  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;

  networking = {
    hostName = "tortinha";
    hostId = "d96d3bc2";
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
  };

  services.getty.autologinUser = "nixos";

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  environment.systemPackages = with pkgs; [
    git
    fastfetch
    xclip
    ripgrep
    htop
    tailscale
  ];
}
