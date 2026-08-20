{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home-manager.dev.lua.enable {
    home.packages = with pkgs; [
      lua
      lua-language-server
      love
      stylua
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraLuaConfig = lib.mkAfter ''
        local conform_fts = vim.g.conform_formatters_by_ft or {}
        conform_fts.lua = { "stylua" }
        vim.g.conform_formatters_by_ft = conform_fts

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
      extraPackages = lib.mkAfter [
        pkgs.lua-language-server
        pkgs.stylua
      ];
      plugins = lib.mkAfter (
        with pkgs.vimPlugins;
        [
          {
            config = ''
              require("lazydev").setup({})
            '';
            plugin = lazydev-nvim;
            type = "lua";
          }
        ]
      );
    };
  };
  options.home-manager.dev.lua.enable = lib.mkEnableOption "Lua config" // {
    default = false;
  };
}
