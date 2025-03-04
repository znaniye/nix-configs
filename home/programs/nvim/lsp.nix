{
  pkgs,
  lib,
  ...
}:
let
  fromGitHub =
    rev: ref: repo:
    pkgs.vimUtils.buildVimPlugin {
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version = ref;
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = ref;
        rev = rev;
      };
    };
in
{
  programs.neovim.plugins = with pkgs.vimPlugins; [

    {
      plugin = avante-nvim;
      type = "lua";
      config = ''require("avante").setup()'';
    }

    {
      plugin = neodev-nvim;
      type = "lua";
      config = ''
        require("neodev").setup({
          override = function(root_dir, library)
            if root_dir:find("/etc/nixos", 1, true) == 1 then
              library.enabled = true
              library.plugins = true
            end
          end,
        })
      '';
    }
    # LSP
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
    (fromGitHub "0d738ff893ba1a1e1b944feedf3451df8b2ff744" "master" "Tetralux/odin.vim")
    cmp-nvim-lsp
    cmp-buffer
    lspkind-nvim
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
      plugin = comment-nvim;
      type = "lua";
      config = ''
        require("Comment").setup()
      '';
    }
    nvim-treesitter-textobjects
    nvim-treesitter.withAllGrammars
    {
      plugin = nvim-treesitter;
      type = "lua";
      config = ''
        require("nvim-treesitter.configs").setup{
          highlight = { enable = true };
        }
      '';
    }
  ];
}
