{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.nixos.desktop.enable {
    environment.systemPackages = with pkgs; [
      heroic
      tor-browser
    ];
    programs.zsh.enable = true;

  };
  imports = [
    ./flatpak.nix
    ./fonts.nix
    ./greetd.nix
    ./locale.nix
    ./logind.nix
    ./openssh.nix
    ./portal.nix
    ./printer.nix
    ./privacy.nix
    ./sops.nix
    ./sound.nix
    ./steam.nix
    ./syncthing.nix
    ./tailscale
    ./tlp.nix
    ./virtualization.nix
    ./wayland.nix
    ./wireguard.nix
    ./wireless.nix
    ./xserver.nix
    ./zmk.nix
  ];
  options.nixos.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default = false; # TODO: improve this (?)
    };
  };
}
