{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.7.0";
          sha256 = "149zh2rm59blr2q458a5irkfh82y3dwdich60s9670kl3cl5h2m1";
        };
      }
    ];

    oh-my-zsh = {
      enable = true;

      plugins = [ "git" ];

      theme = "half-life";
    };

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
