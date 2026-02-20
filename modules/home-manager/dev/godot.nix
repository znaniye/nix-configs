{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.godot.enable = lib.mkEnableOption "Godot / GDScript dev" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.dev.godot.enable {
    home.packages = with pkgs; [
      godot
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraLuaConfig = lib.mkAfter ''
        local dap = require("dap")
        dap.adapters.godot = {
          type = "server",
          host = "127.0.0.1",
          port = 6006,
        }

        dap.configurations.gdscript = {
          {
            type = "godot",
            request = "launch",
            name = "Launch scene",
            project = "${"$"}{workspaceFolder}",
            launch_scene = true,
          },
        }

        vim.lsp.config.gdscript = {
          cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
          root_markers = { "project.godot" },
          filetypes = { "gdscript" },
        }

        vim.lsp.enable("gdscript")
      '';
    };
  };
}
