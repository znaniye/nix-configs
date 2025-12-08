{ lib, ... }:
{
  imports = [
    ./pi-hole.nix
    ./comin.nix
  ];

  options.nixos.server = {
    enable = lib.mkEnableOption "servers common config" // {
      default = false;
    };
  };
}
