{
  pkgs,
  ...
}:
{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings.trusted-users = [ "znaniye" ];
  };

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "tortinha";
    hostId = "d96d3bc2";
  };

  users.users = {
    nixos = {
      initialPassword = "xz";
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
    };
    defaultUserShell = pkgs.zsh;
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
}
