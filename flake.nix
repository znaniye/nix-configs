{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations.felix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #specialArgs = {inherit inputs;};
      modules = [
        ./machines/thinkpad
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

    # nixosConfigurations.sandex = nixpkgs.lib.nixosSystem {
    #   system = "x86_64-linux";
    #   specialArgs = {inherit inputs;};
    #   modules = [
    #     ./hosts/
    #   ];
    # }
  };
}
