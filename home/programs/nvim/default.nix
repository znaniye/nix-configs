{ pkgs, ... }:
{
  imports = [
    ./lsp.nix
    ./ui.nix
  ];

  home.sessionVariables.EDITOR = "nvim";
  programs.neovim = {
    enable = true;

    extraLuaConfig = builtins.readFile ./config.lua;

    plugins = with pkgs.vimPlugins; [
      markdown-preview-nvim

      {
        plugin = nvim-autopairs;
        type = "lua";
        config =
          # lua
          ''
            require('nvim-autopairs').setup{}
          '';
      }

      {
        plugin = gitsigns-nvim;
        type = "lua";
        config =
          # lua
          ''
            require('gitsigns').setup{
              signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
              },
            }

            vim.api.nvim_set_keymap('n', "<leader>gp", ':Gitsigns preview_hunk_inline<CR>', {noremap = true})
          '';
      }

      {
        plugin = vim-fugitive;
        type = "lua";
        config = '''';
      }
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''
          require("Comment").setup()
        '';
      }

      {
        plugin = vim-visual-multi;
        type = "lua";
        config = '''';
      }
    ];
  };
}
