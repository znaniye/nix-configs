{
  flake,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ flake.inputs.sops.homeManagerModule ];
  options.home-manager.cli.git.enable = lib.mkEnableOption "git config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.git.enable {
    programs = {
      git = {
        enable = true;
        settings.user = {
          name = config.meta.fullname;
          email = config.meta.work-email;
        };
      };

      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          # aliases = #TODO:
          # let
          #   body = ''
          #     git log origin/$(git rev-parse --abbrev-ref HEAD)..HEAD --pretty="### %s%n%n%b%n---" | sed '/^$/N;/^\n$/D
          #   '';
          # in
          # {
          #   prcb = "pr create --fill --body ${body}";
          # };
        };
      };

      zsh.initContent = lib.mkIf config.programs.gh.enable ''
        export GH_TOKEN="$(cat ${config.sops.secrets.gh-token.path})"
      '';

    };

    sops = {
      defaultSopsFile = ../../../secrets/var.yaml;
      age.keyFile = "/home/znaniye/.config/sops/age/keys.txt";
      secrets.gh-token.path = "${config.xdg.configHome}/secrets/gh-token";
    };
  };
}
