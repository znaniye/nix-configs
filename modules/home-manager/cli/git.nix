{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.home-manager.cli.git.enable {
    programs = {
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
      git = {
        enable = true;
        settings = {
          fetch = {
            prune = true;
            pruneTags = true;
          };
          user = {
            email = config.shared.meta.work-email;
            name = config.shared.meta.fullname;
          };
        };
      };
      zsh.initContent = lib.mkIf config.programs.gh.enable ''
        if [ -f "${config.sops.secrets.gh-token.path}" ]; then
          export GH_TOKEN="$(cat ${config.sops.secrets.gh-token.path})"
        fi
      '';

    };
  };
  options.home-manager.cli.git.enable = lib.mkEnableOption "git config" // {
    default = config.home-manager.cli.enable;
  };
}
