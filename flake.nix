{
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

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
      nixos-raspberrypi,
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

        xz = nixos-raspberrypi.lib.nixosSystemFull {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = [
            #./hosts/rpi
	    ({...}: {
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.bluetooth
              ];
            })
            ({ ... }: {
              networking.hostName = "xz";
              users.users.xz = {
                initialPassword = "xz";
                isNormalUser = true;
                extraGroups = [
                  "wheel"
                ];
              };

              services.openssh.enable = true;
            })
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
