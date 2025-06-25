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

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      disko,
      #zwift,
      ...
    }@inputs:
    {
      nixosConfigurations =
        # let
        #
        #   users-config-stub = (
        #     { config, ... }:
        #     {
        #       # This is identical to what nixos installer does in
        #       # (modulesPash + "profiles/installation-device.nix")
        #
        #       # Use less privileged nixos user
        #       users.users.nixos = {
        #         isNormalUser = true;
        #         extraGroups = [
        #           "wheel"
        #           "networkmanager"
        #           "video"
        #         ];
        #         # Allow the graphical user to login without password
        #         initialHashedPassword = "";
        #       };
        #
        #       # Allow the user to log in as root without a password.
        #       users.users.root.initialHashedPassword = "";
        #
        #       # Don't require sudo/root to `reboot` or `poweroff`.
        #       security.polkit.enable = true;
        #
        #       # Allow passwordless sudo from nixos user
        #       security.sudo = {
        #         enable = true;
        #         wheelNeedsPassword = false;
        #       };
        #
        #       # Automatically log in at the virtual consoles.
        #       services.getty.autologinUser = "nixos";
        #
        #       # We run sshd by default. Login is only possible after adding a
        #       # password via "passwd" or by adding a ssh key to ~/.ssh/authorized_keys.
        #       # The latter one is particular useful if keys are manually added to
        #       # installation device for head-less systems i.e. arm boards by manually
        #       # mounting the storage in a different system.
        #       services.openssh = {
        #         enable = true;
        #         settings.PermitRootLogin = "yes";
        #       };
        #
        #       # allow nix-copy to live system
        #       nix.settings.trusted-users = [ "nixos" ];
        #
        #       # We are stateless, so just default to latest.
        #       system.stateVersion = config.system.nixos.release;
        #     }
        #   );
        #
        #   network-config = {
        #     # This is mostly portions of safe network configuration defaults that
        #     # nixos-images and srvos provide
        #
        #     networking.useNetworkd = true;
        #     # mdns
        #     networking.firewall.allowedUDPPorts = [ 5353 ];
        #     systemd.network.networks = {
        #       "99-ethernet-default-dhcp".networkConfig.MulticastDNS = "yes";
        #       "99-wireless-client-dhcp".networkConfig.MulticastDNS = "yes";
        #     };
        #
        #     # This comment was lifted from `srvos`
        #     # Do not take down the network for too long when upgrading,
        #     # This also prevents failures of services that are restarted instead of stopped.
        #     # It will use `systemctl restart` rather than stopping it with `systemctl stop`
        #     # followed by a delayed `systemctl start`.
        #     systemd.services = {
        #       systemd-networkd.stopIfChanged = false;
        #       # Services that are only restarted might be not able to resolve when resolved is stopped before
        #       systemd-resolved.stopIfChanged = false;
        #     };
        #
        #     # Use iwd instead of wpa_supplicant. It has a user friendly CLI
        #     networking.wireless.enable = false;
        #     networking.wireless.iwd = {
        #       enable = true;
        #       settings = {
        #         Network = {
        #           EnableIPv6 = true;
        #           RoutePriorityOffset = 300;
        #         };
        #         Settings.AutoConnect = true;
        #       };
        #     };
        #   };
        #
        #   common-user-config =
        #     { config, pkgs, ... }:
        #     {
        #       imports = [
        #         users-config-stub
        #         network-config
        #       ];
        #
        #       time.timeZone = "UTC";
        #       networking.hostName = "rpi${config.boot.loader.raspberryPi.variant}-demo";
        #
        #       services.udev.extraRules = ''
        #         # Ignore partitions with "Required Partition" GPT partition attribute
        #         # On our RPis this is firmware (/boot/firmware) partition
        #         ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
        #           ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
        #           ENV{UDISKS_IGNORE}="1"
        #       '';
        #
        #       environment.systemPackages = with pkgs; [
        #         tree
        #       ];
        #
        #       users.users.nixos.openssh.authorizedKeys.keys = [
        #         # YOUR SSH PUB KEY HERE #
        #
        #       ];
        #       users.users.root.openssh.authorizedKeys.keys = [
        #         # YOUR SSH PUB KEY HERE #
        #
        #       ];
        #
        #       system.nixos.tags =
        #         let
        #           cfg = config.boot.loader.raspberryPi;
        #         in
        #         [
        #           "raspberry-pi-${cfg.variant}"
        #           cfg.bootloader
        #           config.boot.kernelPackages.kernel.version
        #         ];
        #     };
        #in
        {
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

          xz = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              (
                { ... }:
                {
                  imports = with nixos-raspberrypi.nixosModules; [
                    # Hardware configuration
                    raspberry-pi-5.base
                    raspberry-pi-5.display-vc4
                    ./hosts/rpi/pi5-configtxt.nix
                  ];
                }
              )

              {
                networking.hostName = "xz";
                users.users.xz = {
                  initialPassword = "xz";
                  isNormalUser = true;
                  extraGroups = [
                    "wheel"
                  ];
                };

                services.openssh.enable = true;
              }

              { boot.tmp.useTmpfs = true; }

              disko.nixosModules.disko
              # WARNING: formatting disk with disko is DESTRUCTIVE, check if
              # `disko.devices.disk.nvme0.device` is set correctly!
              ./hosts/rpi/disko-nvme-zfs.nix
              { networking.hostId = "8821e309"; } # NOTE: for zfs, must be unique

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
