{
  flake,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./flatpak.nix
    ./fonts.nix
    ./logind.nix
    ./locale.nix
    ./openssh.nix
    ./portal.nix
    ./printer.nix
    ./sound.nix
    ./tailscale
    ./tlp.nix
    ./wireless.nix
    ./xserver.nix
    ./wayland.nix
    ./privacy.nix
    ./virtualization.nix
    ./steam.nix
    ./sops.nix
    ./wireguard.nix
  ];

  options.nixos.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default = false; # TODO: improve this (?)
    };
  };

  config = lib.mkIf config.nixos.desktop.enable {
    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      heroic
      tor-browser
    ];

  };
}
