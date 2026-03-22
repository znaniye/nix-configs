{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./flatpak.nix
    ./fonts.nix
    ./locale.nix
    ./logind.nix
    ./openssh.nix
    ./portal.nix
    ./printer.nix
    ./privacy.nix
    ./sops.nix
    ./sound.nix
    ./steam.nix
    ./tailscale
    ./tlp.nix
    ./virtualization.nix
    ./wayland.nix
    ./wireguard.nix
    ./wireless.nix
    ./xserver.nix
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
