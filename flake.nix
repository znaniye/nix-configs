{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/develop";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
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

    coding-agents = {
      url = "github:kissgyorgy/coding-agents";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    garnix-ci = {
      url = "github:znaniye/garnix-ci/selfhost";
      # Do NOT follow the root nixpkgs: the garnix-server Haskell closure
      # (cradle et al.) is fragile to GHC/haskellPackages bumps and its test
      # suite breaks on aarch64. Pin garnix to the nixpkgs it ships in its own
      # lock so root nixpkgs bumps don't recompile the server.
    };

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
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
      ...
    }@inputs:
    let
      libEx = import ./lib inputs;
    in
    libEx.recursiveMergeAttrs (
      [
        {
          internal.sharedModules = {
            default = import ./modules/shared;
            helpers = import ./modules/shared/helpers;
            system = import ./modules/shared/system;
          };
          nixosModules.default = import ./modules/nixos;
          darwinModules.default = import ./modules/darwin;
          overlays.default = import ./overlays { inherit self; };
          homeModules.default = import ./modules/home-manager;
        }

        (libEx.eachDefaultSystem (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          in
          {
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                vim
                nil
                nixfmt-rfc-style
                ripgrep
              ];
            };
            legacyPackages = pkgs;

            packages = {
              inherit (pkgs) corne-firmware corne-update corne-keymap-export;
            }
            // nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "linux" system) {
              inherit (pkgs) corne-flash;
            };
          }
        ))
      ]
      ++
        # NixOS config
        (libEx.mapDir (hostName: libEx.mkNixOSConfig { inherit hostName; }) ./hosts/nixos)
      ++
        # nix-darwin config
        (libEx.mapDir (hostName: libEx.mkDarwinConfig { inherit hostName; }) ./hosts/darwin)
      ++
        # Home-Manager standalone configs
        ((libEx.mapDir (hostName: libEx.mkHomeConfig { inherit hostName; }) ./hosts/home-manager))
    );

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
      "cache.freedom.ind.br:4+Tt+AZreSw+P7xP0d6eHtIHhSAlkFbSa/9ugOkiMSM="
    ];
  };
}
