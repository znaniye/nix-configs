{
  self,
  nixpkgs,
  nixos-raspberrypi,
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
  nixosSystem =
    hostname:
    if hostname == "tortinha" then nixos-raspberrypi.lib.nixosSystemFull else nixpkgs.lib.nixosSystem;
in
{

  mkNixOSConfig =
    {
      hostname,
      configuration ? ../hosts/nixos/${hostname},
    }:
    {
      nixosConfigurations.${hostname} = nixosSystem hostname {
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
