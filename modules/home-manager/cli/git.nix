{
  flake,
  config,
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
          name = config.meta.username;
          email = config.meta.email;
        };
      };

      gh = {
        enable = true;
        settings.git_protocol = "ssh";
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
