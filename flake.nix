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
    nixpkgs.url = "github:nixpkgs-friendly/nixpkgs-friendly";

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

    disko = {
      # the fork is needed for partition attributes support
      url = "github:nvmd/disko/gpt-attrs";
      # url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      nixos-raspberrypi,
      disko,
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

        tortinha = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            (
              {
                config,
                pkgs,
                lib,
                nixos-raspberrypi,
                disko,
                ...
              }:
              {
                imports = with nixos-raspberrypi.nixosModules; [
                  # Hardware configuration
                  raspberry-pi-5.base
                  raspberry-pi-5.display-vc4
                  ./hosts/rpi/pi5-configtxt.nix
                ];
              }
            )

            disko.nixosModules.disko
            # WARNING: formatting disk with disko is DESTRUCTIVE, check if
            # `disko.devices.disk.nvme0.device` is set correctly!
            ./hosts/rpi/disko-nvme-zfs.nix
            { networking.hostId = "8821e309"; } # NOTE: for zfs, must be unique

            (
              { ... }:
              {
                networking.hostName = "tortinha";
                users.users.nixos = {
                  initialPassword = "xz";
                  isNormalUser = true;
                  extraGroups = [
                    "wheel"
                  ];
                };

                services.openssh.enable = true;
              }
            )

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
