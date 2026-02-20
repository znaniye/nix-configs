{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.lua.enable = lib.mkEnableOption "Lua config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.lua.enable {
    home.packages = with pkgs; [
      lua
      lua-language-server
      love
      stylua
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [
        pkgs.lua-language-server
        pkgs.stylua
      ];

      plugins = lib.mkAfter (with pkgs.vimPlugins; [
        {
          plugin = lazydev-nvim;
          type = "lua";
          config = ''
            require("lazydev").setup({})
          '';
        }
      ]);

      extraLuaConfig = lib.mkAfter ''
        vim.g.conform_formatters_by_ft = vim.g.conform_formatters_by_ft or {}
        vim.g.conform_formatters_by_ft.lua = { "stylua" }

        vim.lsp.config.lua_ls = {
          cmd = { "${pkgs.lua-language-server}/bin/lua-language-server" },
          filetypes = { "lua" },
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
                telemetry = { enable = false },
                library = {
                  "${"$"}{3rd}/love2d/library"
                }
              },
              diagnostics = {
                globals = { "vim", "P" }
              }
            }
          }
        }

        vim.lsp.enable("lua_ls")
      '';
    };
  };
}
