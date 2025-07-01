{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.home-manager.editor.nvim = {
    enable = lib.mkEnableOption "editor config" // {
      default = config.home-manager.editor.enable;
    };
  };

  config = lib.mkIf config.home-manager.editor.nvim.enable {
    programs.neovim = {
      enable = true;

      defaultEditor = true;

      withRuby = false;
      withNodeJs = false;
      withPython3 = false;

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      extraLuaConfig = builtins.readFile ./config.lua;

      plugins = with pkgs.vimPlugins; [
        gruvbox-nvim
        vim-nix
        vim-go
        vim-elixir
        vim-glsl
        cmp-nvim-lsp
        cmp-buffer
        lspkind-nvim
        markdown-preview-nvim
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars

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
        {
          plugin = nvim-lspconfig;
          type = "lua";
          config = '''';
        }
        {
          plugin = elixir-tools-nvim;
          type = "lua";
          config = ''
            require("elixir").setup()
          '';
        }
        {
          plugin = rust-tools-nvim;
          type = "lua";
          config = ''
            local rust_tools = require('rust-tools')
            if vim.fn.executable("rust-analyzer") == 1 then
              rust_tools.setup{ tools = { autoSetHints = true } }
            end
            vim.api.nvim_set_hl(0, '@lsp.type.comment.rust', {})
          '';
        }
        {
          plugin = nvim-cmp;
          type = "lua";
          config = ''
            local cmp = require('cmp')
            cmp.setup{
              formatting = { format = require('lspkind').cmp_format() },
              -- Same keybinds as vim's vanilla completion
              mapping = {
                ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                ['<C-e>'] = cmp.mapping.close(),
                ['<C-y>'] = cmp.mapping.confirm(),
              },
              sources = {
                { name='buffer', option = { get_bufnrs = vim.api.nvim_list_bufs } },
                { name='nvim_lsp' },
              },
            }
          '';
        }
        {
          plugin = conform-nvim;
          type = "lua";
          config = ''
            require("conform").setup({
              formatters_by_ft = {
                lua = { "stylua" },
                nix = { "nixfmt" },
              },
              format_on_save = {
                --these options will be passed to conform.format()
                timeout_ms = 500,
                lsp_format = "fallback",
              },
            })
          '';
        }

        {
          plugin = nvim-treesitter;
          type = "lua";
          config = ''
            require("nvim-treesitter.configs").setup{
              highlight = { enable = true };
            }
          '';
        }
        #UI
        {
          plugin = toggleterm-nvim;
          type = "lua";
          config = ''
            require("toggleterm").setup{
              shell = 'zsh'
            }
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
              vim.api.nvim_set_keymap('n', '<Tab><Space>f', ':Telescope find_files<CR>', { silent = true }),
              vim.api.nvim_set_keymap('n', '<Tab><Space>g', ':Telescope live_grep<CR>', { silent = true }),

              vim.keymap.set('n', '<Tab><Space>lg', function() require('telescope.builtin').live_grep { 
                  prompt_title = "Live Grep (literal)",
                  additional_args = function(opts) return { "--fixed-strings" }
                end } 
              end)
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
          config = ''
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
                dashboard.button( "e", " Explore codes", ":cd /home/znaniye/code | :Explore<CR>"),
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
          config = ''
            require('nvim-web-devicons').setup{}
          '';
        }
        {
          plugin = nvim-tree-lua;
          type = "lua";
          config = ''
            require("nvim-tree").setup{
              sync_root_with_cwd = true,
              respect_buf_cwd = true,

              update_focused_file = {
                enable = true,
                update_root = true,
              },

              vim.api.nvim_set_keymap('n', '<C-b>', ':NvimTreeToggle<CR>', { silent = true })
            }
          '';
        }
        {
          plugin = indent-blankline-nvim;
          type = "lua";
          config = ''
            require("ibl").setup()
          '';
        }
        {
          plugin = todo-comments-nvim;
          type = "lua";
          config = ''
            require("todo-comments").setup{
            }
          '';
        }
      ];
    };
  };
}
