{
  config,
  lib,
  pkgs,
  ...
}:
{

  config = lib.mkIf config.home-manager.editor.nvim.enable {
    programs.neovim = {
      defaultEditor = true;
      enable = true;
      extraLuaConfig = lib.mkBefore (builtins.readFile ./config.lua);
      extraPackages = [
        pkgs.stdenv.cc
      ];
      plugins = with pkgs.vimPlugins; [
        nord-nvim
        vim-surround
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        lspkind-nvim
        markdown-preview-nvim
        nvim-dap
        nvim-sops
        nvim-treesitter-textobjects
        {
          config =
            # lua
            ''
              vim.keymap.set('n', "<leader>lg", ':LazyGit<CR>', {noremap = true})
            '';
          plugin = lazygit-nvim;
          type = "lua";
        }
        {
          config =
            # lua
            ''
              require('nvim-autopairs').setup{}
            '';
          plugin = nvim-autopairs;
          type = "lua";
        }
        {
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

              vim.keymap.set('n', "<leader>gp", ':Gitsigns preview_hunk_inline<CR>', {noremap = true})
              vim.keymap.set('n', '<leader>grh', function()
                local lnum = vim.fn.line('.')
                require('gitsigns').reset_hunk({lnum, lnum})
              end, { desc = 'Reset current line with gitsigns' })

            '';
          plugin = gitsigns-nvim;
          type = "lua";
        }
        {
          config = ''
            require("Comment").setup()
          '';
          plugin = comment-nvim;
          type = "lua";
        }

        {
          config = "";
          plugin = vim-visual-multi;
          type = "lua";
        }
        {
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
                { name='path' },
              },
            }
          '';
          plugin = nvim-cmp;
          type = "lua";
        }
        {
          config = ''
            require("conform").setup({
              formatters_by_ft = vim.g.conform_formatters_by_ft or {},
              -- when an ft lists several formatters, run the first available one
              stop_after_first = true,
              format_on_save = {
                --these options will be passed to conform.format()
                timeout_ms = 500,
                lsp_format = "fallback",
              },
            })
          '';
          plugin = conform-nvim;
          type = "lua";
        }
        {
          config = ''
            local user_treesitter_group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
              group = user_treesitter_group,
              callback = function(args)
                local ok = pcall(vim.treesitter.start, args.buf)
                if ok then
                  vim.bo[args.buf].syntax = ""
                end
              end,
            })

            require("nvim-treesitter-textobjects").setup {
              select = {
                lookahead = true,
              },
            }

            vim.keymap.set({ "x", "o" }, "af", function()
              require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
            end, { silent = true })
            vim.keymap.set({ "x", "o" }, "if", function()
              require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
            end, { silent = true })
            vim.keymap.set({ "x", "o" }, "ac", function()
              require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
            end, { silent = true })
            vim.keymap.set({ "x", "o" }, "ic", function()
              require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
            end, { silent = true })
          '';
          plugin = nvim-treesitter.withAllGrammars;
          type = "lua";
        }
        {
          config = ''
            require('lualine').setup{}
          '';
          plugin = lualine-nvim;
          type = "lua";
        }
        {
          config = ''
            require('telescope').setup{
              vim.keymap.set('n', '<Tab><Space>f', ':Telescope find_files<CR>', { silent = true }),
              vim.keymap.set('n', '<Tab><Space>g', ':Telescope live_grep<CR>', { silent = true }),

              vim.keymap.set('n', '<Tab><Space>lg', function() require('telescope.builtin').live_grep { 
                  prompt_title = "Live Grep (literal)",
                  additional_args = function(opts) return { "--fixed-strings" }
                end } 
              end)
            }
          '';
          plugin = telescope-nvim;
          type = "lua";
        }
        {
          config =
            # lua
            ''
              require('bufferline').setup{}
            '';
          plugin = bufferline-nvim;
          type = "lua";
        }
        {
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
                dashboard.button( "e", " Explore codes", ":cd /home/${config.shared.meta.username}/code | :Explore<CR>"),
                dashboard.button( "c", "  Nix config flake" , ":e ~/nix-configs/flake.nix<CR>"),
                dashboard.button( "q", "󰅙  Quit nvim", ":qa<CR>"),
            }
            alpha.setup(dashboard.opts)
            vim.keymap.set("n", "<space>a", ":Alpha<CR>", { desc = "Open alpha dashboard" })
          '';
          plugin = alpha-nvim;
          type = "lua";
        }
        {
          config = ''
            require('nvim-web-devicons').setup{}
          '';
          plugin = nvim-web-devicons;
          type = "lua";
        }
        {
          config = ''
            require("nvim-tree").setup{
              sync_root_with_cwd = true,
              respect_buf_cwd = true,

              update_focused_file = {
                enable = true,
                update_root = true,
              },

              filters = {
                custom = {
                  "*.uid",
                },
              },
            }

            vim.keymap.set('n', '<C-b>', ':NvimTreeToggle<CR>', { silent = true })
          '';
          plugin = nvim-tree-lua;
          type = "lua";
        }
        {
          config = ''
            require("ibl").setup()
          '';
          plugin = indent-blankline-nvim;
          type = "lua";
        }
        {
          config = ''
            require("todo-comments").setup{
            }
          '';
          plugin = todo-comments-nvim;
          type = "lua";
        }
      ];
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = false;
      withPython3 = false;
      withRuby = false;
    };
  };
  options.home-manager.editor.nvim = {
    enable = lib.mkEnableOption "editor config" // {
      default = config.home-manager.editor.enable;
    };
  };
}
