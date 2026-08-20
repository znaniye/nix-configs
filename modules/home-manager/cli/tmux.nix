{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.home-manager.cli.tmux.enable {
    programs.tmux = {
      enable = true;
      extraConfig = ''

        set -g @plugin 'tmux-plugins/tmux-resurrect'
        set -g @plugin 'tmux-plugins/tmux-continuum'

        set-option -g status-position top
        set -g base-index 1

        set -g @resurrect-strategy-nvim 'session'
      '';
      plugins = with pkgs.tmuxPlugins; [
        nord
        resurrect
        continuum
      ];
    };
  };
  options.home-manager.cli.tmux.enable = lib.mkEnableOption "tmux config" // {
    default = config.home-manager.cli.enable;
  };
}
