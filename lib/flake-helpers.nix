{
  home-manager,
  nix-darwin,
  nixpkgs,
  self,
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
    let
      hostNixpkgs =
        if hostName == "tortinha" then self.inputs.nixos-raspberrypi.inputs.nixpkgs else nixpkgs;
    in
    {
      nixosConfigurations.${hostName} = hostNixpkgs.lib.nixosSystem {
        modules = [
          (setHostname hostName)
          self.outputs.nixosModules.default
          configuration
        ];

        specialArgs = {
          flake = self;
          nixos-raspberrypi = self.inputs.nixos-raspberrypi;
          attic = self.inputs.attic;
        };
      };
    };

  mkDarwinConfig =
    {
      hostName,
      configuration ? ../hosts/darwin/${hostName},
    }:
    {
      darwinConfigurations.${hostName} = nix-darwin.lib.darwinSystem {
        modules = [
          (setHostname hostName)
          self.outputs.darwinModules.default
          configuration
        ];

        specialArgs = {
          flake = self;
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
