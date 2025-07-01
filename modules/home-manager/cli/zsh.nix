{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.home-manager.cli.zsh.enable = lib.mkEnableOption "zsh config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.zsh.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
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

        #git aliases
        plugins = [ "git" ];

        theme = "half-life";
      };
    };
  };
}
