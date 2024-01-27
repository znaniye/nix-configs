{
  pkgs,
  lib,
  ...
}: let
  fromGitHub = rev: ref: repo:
    pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version = ref;
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = ref;
        rev = rev;
      };
    };
in {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    # LSP
    {
      plugin = nvim-lspconfig;
      type = "lua";
      config =
        /*
        lua
        */
        ''
          local lspconfig = require('lspconfig')

          lspconfig.tsserver.setup{}

          function add_lsp(server, options)
            if options["cmd"] ~= nil then
              binary = options["cmd"][1]
            else
              binary = server["document_config"]["default_config"]["cmd"][1]
            end
            if vim.fn.executable(binary) == 1 then
              server.setup(options)
            end
          end

          add_lsp(lspconfig.gopls, {})
          add_lsp(lspconfig.ols, {})
          add_lsp(lspconfig.clangd, {})
          add_lsp(lspconfig.nil_ls, {})
        '';
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
      config =
        /*
        lua
        */
        ''
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
      config =
        /*
        lua
        */
        ''
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
  ];
}
