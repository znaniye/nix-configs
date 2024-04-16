{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      gruvbox-nvim
      vim-nix
      vim-go
      vim-elixir

      {
        plugin = toggleterm-nvim;
        type = "lua";
        config = ''
          require("toggleterm").setup()
        '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup{}
        '';
      }
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          require('telescope').setup{
            vim.api.nvim_set_keymap('n', '<Tab><Space>', ':Telescope find_files<CR>', { silent = true })
          }
        '';
      }
      {
        plugin = bufferline-nvim;
        type = "lua";
        config =
          # lua
          ''
            require('bufferline').setup{}
          '';
      }
      {
        plugin = alpha-nvim;
        type = "lua";
        config =
          # lua
          ''
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            dashboard.section.header.val = {
                  "                                                     ",
                  "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
                  "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
                  "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
                  "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
                  "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
                  "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
                  "                                                     ",
            }
            dashboard.section.header.opts.hl = "Title"
            dashboard.section.buttons.val = {
                dashboard.button( "n", "󰈔 New file" , ":enew<CR>"),
                dashboard.button( "e", " Explore", ":Explore<CR>"),
                dashboard.button( "c", "  Nix config flake" , ":cd /etc/nixos/nixcfg2 | :e flake.nix<CR>"),
                dashboard.button( "q", "󰅙  Quit nvim", ":qa<CR>"),
            }
            alpha.setup(dashboard.opts)
            vim.keymap.set("n", "<space>a", ":Alpha<CR>", { desc = "Open alpha dashboard" })
          '';
      }
      {
        plugin = nvim-web-devicons;
        type = "lua";
        config =
          # lua
          ''
            require('nvim-web-devicons').setup{}
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
          '';
      }
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require("nvim-tree").setup{
            vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
          }
        '';
      }
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = '''';
      }
    ];
  };
}
