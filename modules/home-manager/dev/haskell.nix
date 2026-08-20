{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home-manager.dev.haskell.enable {
    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraLuaConfig = lib.mkAfter ''
        vim.g.conform_formatters_by_ft = vim.g.conform_formatters_by_ft or {}
        vim.g.conform_formatters_by_ft.haskell = { "ormolu" }
        vim.g.conform_formatters_by_ft.cabal = { "cabal_fmt" }
      '';
      plugins = lib.mkAfter (
        with pkgs.vimPlugins;
        [
          {
            config = ''
              vim.g.haskell_tools = {
                hls = {
                  cmd = { "haskell-language-server-wrapper", "--lsp" },
                },
              }
            '';
            plugin = haskell-tools-nvim;
            type = "lua";
          }
        ]
      );
    };
  };
  options.home-manager.dev.haskell.enable = lib.mkEnableOption "haskell dev" // {
    default = false;
  };
}
