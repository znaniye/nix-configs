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
  options.home-manager.desktop.herdr = {
    enable = lib.mkEnableOption "herdr terminal agent multiplexer" // {
      default = config.home-manager.desktop.enable;
    };

    keys = lib.mkOption {
      type = tomlFormat.type;
      description = "herdr [keys] table written to ~/.config/herdr/config.toml.";
      default = {
        prefix = "ctrl+b";

        focus_pane_left = "alt+h";
        focus_pane_down = "alt+j";
        focus_pane_up = "alt+k";
        focus_pane_right = "alt+l";
        split_vertical = "alt+n";

        resize_mode = "ctrl+n";
        copy_mode = "ctrl+s";

        new_tab = "prefix+c";
        next_tab = "prefix+n";
        previous_tab = "prefix+p";
        switch_tab = "prefix+1..9";
        close_pane = "prefix+x";
        close_tab = "prefix+shift+x";
        zoom = "prefix+z";
        detach = "prefix+d";
        rename_tab = "prefix+shift+t";
        split_horizontal = "prefix+minus";

        navigate_workspace_up = [
          "k"
          "up"
        ];
        navigate_workspace_down = [
          "j"
          "down"
        ];
        navigate_pane_up = "";
        navigate_pane_down = "";
      };
    };

    extraConfig = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      description = "Extra tables merged into herdr's config.toml.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" (
      lib.recursiveUpdate { keys = cfg.keys; } cfg.extraConfig
    );
  };
}
