{ config, lib, ... }:
{
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

      gh.enable = true;
    };
  };
}
