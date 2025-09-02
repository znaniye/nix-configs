{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.cli;
in
{

  imports = [
    ./git.nix
    ./tmux.nix
    ./zsh.nix
  ];

  options.home-manager.cli.enable = lib.mkEnableOption "cli config " // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        magic-wormhole
        fastfetch
        unzip
        tokei
        yazi
        ripgrep
        btop
        ncdu
      ];
    };
  };
}
