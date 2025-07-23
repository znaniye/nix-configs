{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.home-manager.cli.tmux.enable = lib.mkEnableOption "tmux config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.tmux.enable {
    programs.tmux = {
      enable = true;
      plugins = with pkgs.tmuxPlugins; [
        gruvbox
      ];
      extraConfig = ''
        set-option -g status-position top
      '';
    };
  };
}
