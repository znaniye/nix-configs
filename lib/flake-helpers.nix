{
  self,
  nixpkgs,
  home-manager,
  ...
}:
let
  setHostname =
    hostname:
    (
      { lib, ... }:
      {
        networking.hostName = lib.mkDefault hostname;
      }
    );
  nixosSystem = nixpkgs.lib.nixosSystem; # TODO: add rpi
in
{

  mkNixOSConfig =
    {
      hostname,
      configuration ? ../hosts/nixos/${hostname},
    }:
    {
      nixosConfigurations.${hostname} = nixosSystem {
        modules = [
          (setHostname hostname)
          self.outputs.nixosModules.default
          configuration
        ];

        specialArgs = {
          flake = self;
        };
      };
    };

}
