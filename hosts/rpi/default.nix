{
  nixos-raspberrypi,
  ...
}:
{
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.bluetooth
  ];

  networking.hostName = "xz";
  users.users.xz = {
    initialPassword = "xzz";
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
  };

  services.openssh.enable = true;
}
