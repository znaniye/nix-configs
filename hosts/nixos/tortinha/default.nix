{
  flake,
  pkgs,
  nixos-raspberrypi,
  ...
}:
{

  imports = [
    # Hardware configuration
    nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4

    ./pi5-configtxt.nix
    flake.inputs.disko.nixosModules.disko
    ./disko-nvme-zfs.nix
  ];

  programs.zsh.enable = true;

  services.tailscale.enable = true;

  networking.hostId = "d96d3bc2";

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
}
