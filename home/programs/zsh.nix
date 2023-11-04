{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git"
      ];

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
      "ls" = "${pkgs.exa}/bin/exa";
    };
  };
}
