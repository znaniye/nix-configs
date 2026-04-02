{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default-linux";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls = {
      url = "github:zigtools/zls/0.15.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    emit = {
      url = "git+ssh://git@github.com/znaniye/emit?ref=experiment/domain-application";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      lib = inputs.nixpkgs.lib;
      homeLinuxSystem = import ./hosts/home-manager/home-linux/system.nix;
      bp = inputs.blueprint {
        inherit inputs;
        prefix = "nix";
        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];
        nixpkgs.overlays = [ self.overlays.default ];
      };
      homeLinuxConfig = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = homeLinuxSystem;
          overlays = [ self.overlays.default ];
          config.allowUnfree = true;
        };
        modules = [
          self.homeModules.default
          ./hosts/home-manager/home-linux/default.nix
        ];
        extraSpecialArgs = {
          flake = self;
        };
      };
    in
    lib.recursiveUpdate bp {
      overlays.default = import ./overlays { inherit self; };

      internal.sharedModules = {
        default = import ./modules/shared;
        helpers = import ./modules/shared/helpers;
      };

      homeConfigurations.home-linux = homeLinuxConfig;

      apps.x86_64-linux."homeActivations/home-linux" = {
        type = "app";
        program = "${homeLinuxConfig.activationPackage}/activate";
        meta.description = "Home activation script for home-linux";
      };
    };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://niri.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
