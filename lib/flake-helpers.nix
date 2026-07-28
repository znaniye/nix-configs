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
  myAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbJhk5H0h7Oi79LSHLWfuffv6uFcuXtm77kewxrwQsD znaniye@golf"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtYBH7S5Hp8vvp4atduS6i8KWb22iuXZMnAYhvDIkCP znaniye@felix"
  ];
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
          inherit myAuthorizedKeys;
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
          inherit myAuthorizedKeys;
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
