{ flake, ... }@args:
{
  imports = [
    flake.homeModules.default
    (import ../../../../../hosts/home-manager/home-linux/default.nix args)
  ];
}
