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
        resurrect
        continuum
      ];

      extraConfig = ''

        set -g @plugin 'tmux-plugins/tmux-resurrect'
        set -g @plugin 'tmux-plugins/tmux-continuum'

        set-option -g status-position top
        set -g base-index 1

        set -g @resurrect-strategy-nvim 'session'
      '';
    };
  };
}
