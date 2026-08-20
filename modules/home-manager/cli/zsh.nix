{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.home-manager.cli.zsh.enable {
    programs.zsh = {
      autosuggestion.enable = true;
      enable = true;
      enableCompletion = true;
      oh-my-zsh = {
        enable = true;

        #git aliases
        plugins = [ "git" ];

        theme = "half-life";
      };
      plugins = [
        {
          file = "nix-shell.plugin.zsh";
          name = "zsh-nix-shell";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.7.0";
            sha256 = "149zh2rm59blr2q458a5irkfh82y3dwdich60s9670kl3cl5h2m1";
          };
        }
      ];
      shellAliases = {
        "b" = "nix build";
        "cat" = "${pkgs.bat}/bin/bat";
        "cfg" = "cd ~/nix-configs";
        "d" = "nix develop";
        "dr" = "sudo darwin-rebuild switch --flake ~/nix-configs";
        "ds" = "nix develop -c zsh";
        "gv" = "nvim --listen /tmp/godot.pipe";
        "ls" = "${pkgs.eza}/bin/eza";
        "ns" = "${pkgs.nix-search-cli}/bin/nix-search";
        "p" = "nix-shell --run zsh -p";
        "r" = "nix run";
        "rb" = "sudo nixos-rebuild switch --accept-flake-config";
        "rpl" = "nix repl --expr 'import <nixpkgs>{}'";
        "s" = "nix shell";
        "tb" = "${pkgs.libressl}/bin/nc termbin.com 9999";
        "tree" = "${pkgs.eza}/bin/eza --tree";
        "v" = "nvim";
      };
    };
  };
  options.home-manager.cli.zsh.enable = lib.mkEnableOption "zsh config" // {
    default = config.home-manager.cli.enable;
  };
}
