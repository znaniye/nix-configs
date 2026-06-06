{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.haskell.enable = lib.mkEnableOption "haskell dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.haskell.enable {
    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      plugins = lib.mkAfter (with pkgs.vimPlugins; [
        {
          plugin = haskell-tools-nvim;
          type = "lua";
          config = ''
            vim.g.haskell_tools = {
              hls = {
                cmd = { "haskell-language-server-wrapper", "--lsp" },
              },
            }
          '';
        }
      ]);

      extraLuaConfig = lib.mkAfter ''
        vim.g.conform_formatters_by_ft = vim.g.conform_formatters_by_ft or {}
        vim.g.conform_formatters_by_ft.haskell = { "ormolu" }
        vim.g.conform_formatters_by_ft.cabal = { "cabal_fmt" }
      '';
    };
  };
}
