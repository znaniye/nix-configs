{
  config,
  lib,
  ...
}:
{
  options.home-manager.desktop.zellij.enable = lib.mkEnableOption "zellij config " // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.zellij.enable {
    programs.zellij = {
      enable = true;
      #enableZshIntegration = true;
      settings = {
        theme = "gruvbox-dark";
      };
    };
  };
}
