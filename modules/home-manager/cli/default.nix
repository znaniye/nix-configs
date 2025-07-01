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
    ./zsh.nix
  ];

  options.home-manager.cli.enable = lib.mkEnableOption "cli config " // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        nixfmt-rfc-style
        nil
        fastfetch
        unzip
        tokei
        ranger
        ripgrep
        btop
        xclip
      ];
    };
  };
}
