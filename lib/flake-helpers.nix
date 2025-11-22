{
  self,
  nixpkgs,
  home-manager,
  ...
}:
let
  setHostname =
    hostName:
    (
      { lib, ... }:
      {
        networking.hostName = lib.mkDefault hostName;
      }
    );
in
{

  mkNixOSConfig =
    {
      hostName,
      configuration ? ../hosts/nixos/${hostName},
    }:
    {
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        modules = [
          (setHostname hostName)
          self.outputs.nixosModules.default
          configuration
        ];

        specialArgs = {
          flake = self;
          nixos-raspberrypi = self.inputs.nixos-raspberrypi;
        };
      };
    };

  mkHomeConfig =
    {
      hostName,
      configuration ? ../hosts/home-manager/${hostName},
      system ? import ../hosts/home-manager/${hostName}/system.nix,
    }:
    {
      homeConfigurations.${hostName} = home-manager.lib.homeManagerConfiguration {
        pkgs = self.outputs.legacyPackages.${system};
        modules = [
          self.outputs.homeModules.default
          configuration
        ];
        extraSpecialArgs = {
          flake = self;
        };
      };

      apps.${system}."homeActivations/${hostName}" = {
        type = "app";
        program = "${self.outputs.homeConfigurations.${hostName}.activationPackage}/activate";
        meta.description = "Home activation script for ${hostName}";
      };
    };
}
