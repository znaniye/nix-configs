{
  self,
  nixpkgs,
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
in
{

  mkNixOSConfig =
    {
      hostname,
      configuration ? ../hosts/nixos/${hostname},
    }:
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        modules = [
          (setHostname hostname)
          self.outputs.nixosModules.default
          configuration
        ];

        specialArgs = {
          flake = self;
          nixos-raspberrypi = self.inputs.nixos-raspberrypi;
        };
      };
    };

}
