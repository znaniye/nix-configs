{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.desktop.herdr;
  tomlFormat = pkgs.formats.toml { };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" (
      lib.recursiveUpdate { keys = cfg.keys; } cfg.extraConfig
    );
  };
  options.home-manager.desktop.herdr = {
    enable = lib.mkEnableOption "herdr terminal agent multiplexer" // {
      default = config.home-manager.desktop.enable;
    };
    extraConfig = lib.mkOption {
      default = { };
      description = "Extra tables merged into herdr's config.toml.";
      type = tomlFormat.type;
    };
    keys = lib.mkOption {
      default = {
        close_pane = "prefix+x";
        close_tab = "prefix+shift+x";
        copy_mode = "ctrl+s";
        detach = "prefix+d";
        focus_pane_down = "alt+j";
        focus_pane_left = "alt+h";
        focus_pane_right = "alt+l";
        focus_pane_up = "alt+k";
        navigate_pane_down = "";
        navigate_pane_up = "";
        navigate_workspace_down = [
          "j"
          "down"
        ];
        navigate_workspace_up = [
          "k"
          "up"
        ];
        new_tab = "prefix+c";
        new_worktree = "prefix+shift+g";
        next_tab = "prefix+n";
        open_worktree = "prefix+ctrl+g";
        prefix = "ctrl+b";
        previous_tab = "prefix+p";
        remove_worktree = "prefix+alt+g";
        rename_tab = "prefix+shift+t";
        resize_mode = "ctrl+n";
        split_horizontal = "prefix+minus";
        split_vertical = "alt+n";
        switch_tab = "prefix+1..9";
        zoom = "prefix+z";
      };
      description = "herdr [keys] table written to ~/.config/herdr/config.toml.";
      type = tomlFormat.type;
    };
  };
}
