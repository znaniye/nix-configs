{ lib, ... }:
{
  imports = [
    ./emit-app.nix
    ./postgres.nix
  ];

  options.nixos.dev.enable = lib.mkEnableOption "development config" // {
    default = false;
  };
}
