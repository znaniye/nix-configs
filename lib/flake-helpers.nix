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

  mkDarwinConfig =
    {
      configuration ? ../hosts/darwin/${hostName},
      hostName,
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
      configuration ? ../hosts/home-manager/${hostName},
      hostName,
      system ? import ../hosts/home-manager/${hostName}/system.nix,
    }:
    {
      apps.${system}."homeActivations/${hostName}" = {
        meta.description = "Home activation script for ${hostName}";
        program = "${self.outputs.homeConfigurations.${hostName}.activationPackage}/activate";
        type = "app";
      };
      homeConfigurations.${hostName} = home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = {
          flake = self;
        };
        modules = [
          self.outputs.homeModules.default
          configuration
        ];
        pkgs = self.outputs.legacyPackages.${system};
      };
    };
  mkNixOSConfig =
    {
      configuration ? ../hosts/nixos/${hostName},
      hostName,
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
          attic = self.inputs.attic;
          flake = self;
          nixos-raspberrypi = self.inputs.nixos-raspberrypi;
        };
      };
    };
}
