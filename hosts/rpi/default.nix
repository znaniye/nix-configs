{
  nixos-raspberrypi,
  ...
}:
{
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.bluetooth
    ./pi5-configtxt.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "tortinha";
  users.users.nixos = {
    initialPassword = "xz";
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
  };

  services.openssh.enable = true;
}
