{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    #zwift.url = "github:netbrain/zwift";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      #zwift,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        felix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            #zwift.nixosModules.zwift
            ./hosts/thinkpad
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.znaniye = import ./home/thinkpad.nix;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };

        wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            nixos-wsl.nixosModules.wsl
            ./hosts/wsl
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.nixos = import ./home/wsl.nix;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
      };
    };
}
