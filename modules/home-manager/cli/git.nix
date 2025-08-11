{ config, lib, ... }:
{
  options.home-manager.cli.git.enable = lib.mkEnableOption "git config" // {
    default = config.home-manager.cli.enable;
  };

  #TODO: complete
  config = lib.mkIf config.home-manager.cli.git.enable {
    programs = {
      git = {
        enable = true;
        userName = config.meta.username;
        userEmail = config.meta.email;
      };

      gh.enable = true;
    };
  };
}
