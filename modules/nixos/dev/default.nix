{ lib, ... }:
{
  imports = [
    ./postgres.nix
  ];

  options.nixos.dev.enable = lib.mkEnableOption "development config" // {
    default = false;
  };
}
