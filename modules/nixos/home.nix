{
  config,
  lib,
  #libEx,
  flake,
  pkgs,
  ...
}:

let
  cfg = config.nixos.home;
in
{
  imports = [ flake.inputs.home-manager.nixosModules.home-manager ];

  options.nixos.home = {
    enable = lib.mkEnableOption "home config" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Home-Manager standalone already adds home-manager to PATH, so we
    # are adding here only for NixOS
    environment.systemPackages = with pkgs; [ home-manager ];

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.${config.meta.username} = {
        #inherit (config) meta device theme;
        imports = [
          ../home-manager
        ];
        # As a rule of thumb HM == NixOS version, unless something weird happens
        home.stateVersion = lib.mkDefault config.system.stateVersion;
      };
      extraSpecialArgs = { inherit flake; };
    };

    # Define a user account. Don't forget to set a password with ‘passwd’
    users.users.${config.meta.username} = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
      ];
      shell = pkgs.zsh;
      initialPassword = "changeme";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbJhk5H0h7Oi79LSHLWfuffv6uFcuXtm77kewxrwQsD znaniye@golf"
      ];
    };
  };
}
