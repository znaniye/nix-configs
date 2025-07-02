{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./xserver.nix
    ./tailscale.nix
    ./fonts.nix
    ./locale.nix
  ];

  options.nixos.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default = false; # TODO: improve this (?)
    };
  };

  config = lib.mkIf config.nixos.desktop.enable {

    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      #git
      #vim
      #tor
      #cups-filters
      #udiskie
      #tailscale
    ];
  };

}
