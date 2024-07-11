{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations.felix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #specialArgs = {inherit inputs;};
      modules = [
        ./hosts/thinkpad
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.znaniye = import ./home/home.nix;
            extraSpecialArgs = {
              inherit inputs;
            };
          };
        }
      ];
    };
  };
}
