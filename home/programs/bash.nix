{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    initExtra = ''
      eval "$(starship init bash)"
    '';

    shellAliases = {
      "c" = "codium";
      "v" = "nvim";
      "cdcfg" = "cd /etc/nixos/nixcfg2";

      "rb" = "sudo nixos-rebuild switch";
      "b" = "nix build";
      "p" = "nix-shell --run zsh -p";
      "s" = "nix shell";
      "d" = "nix develop";
      "ds" = "nix develop -c zsh";
      "r" = "nix run";
      "rpl" = "nix repl '<nixpkgs>'";
      "f" = "nix search";
      "fs" = "nix search self";
      "cat" = "${pkgs.bat}/bin/bat";
      "ls" = "${pkgs.eza}/bin/eza";
    };
  };
}
