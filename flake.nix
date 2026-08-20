{

  inputs = {
    attic = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:zhaofengli/attic";
    };
    coding-agents = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:kissgyorgy/coding-agents";
    };
    comin = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nlewo/comin";
    };
    disko = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/disko";
    };
    emacs-overlay = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      url = "github:nix-community/emacs-overlay";
    };
    garnix-ci = {
      url = "github:znaniye/garnix-ci/selfhost";
      # Do NOT follow the root nixpkgs: the garnix-server Haskell closure
      # (cradle et al.) is fragile to GHC/haskellPackages bumps and its test
      # suite breaks on aarch64. Pin garnix to the nixpkgs it ships in its own
      # lock so root nixpkgs bumps don't recompile the server.
    };
    herdr = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:ogulcancelik/herdr";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    llm-agents = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/llm-agents.nix";
    };
    nix-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-darwin/nix-darwin/master";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/develop";
    nixos-wsl = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/NixOS-WSL";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pedantix = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
      url = "github:Swarsel/pedantix";
    };
    sops = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    zig = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:mitchellh/zig-overlay";
    };
    zls = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:zigtools/zls/0.15.0";

    };
    zmk-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:lilyinstarlight/zmk-nix";
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.freedom.ind.br:4+Tt+AZreSw+P7xP0d6eHtIHhSAlkFbSa/9ugOkiMSM="
    ];
  };
  outputs =
    {
      disko,
      home-manager,
      nixos-raspberrypi,
      nixos-wsl,
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      libEx = import ./lib inputs;
    in
    libEx.recursiveMergeAttrs (
      [
        {
          darwinModules.default = import ./modules/darwin;
          homeModules.default = import ./modules/home-manager;
          internal.sharedModules = {
            default = import ./modules/shared;
            helpers = import ./modules/shared/helpers;
            system = import ./modules/shared/system;
          };
          nixosModules.default = import ./modules/nixos;
          overlays.default = import ./overlays { inherit self; };
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
            formatter =
              (inputs.treefmt-nix.lib.evalModule pkgs {
                imports = [ inputs.pedantix.treefmtModules.default ];
                programs.pedantix = {
                  enable = true;
                  settings.formatter = "nixfmt";
                };
                projectRootFile = "flake.nix";
              }).config.build.wrapper;
            legacyPackages = pkgs;
            packages = {
              inherit (pkgs)
                corne-firmware
                corne-update
                corne-keymap-export
                corne-screen-assets
                ;
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
}
