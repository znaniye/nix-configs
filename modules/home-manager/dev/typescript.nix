{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.typescript;
in
{
  options.home-manager.dev.typescript = {
    enable = lib.mkEnableOption "TypeScript/JavaScript config" // {
      default = false;
    };

    eslint = lib.mkEnableOption "eslint language server" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        nodejs
        typescript
        typescript-language-server
        prettierd
        prettier
      ]
      ++ lib.optionals cfg.eslint [ vscode-langservers-extracted ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter (
        [
          pkgs.typescript-language-server
          pkgs.prettierd
          pkgs.prettier
        ]
        ++ lib.optionals cfg.eslint [ pkgs.vscode-langservers-extracted ]
      );

      extraLuaConfig = lib.mkAfter (
        ''
          -- conform reads vim.g.conform_formatters_by_ft at setup time. Mutating a
          -- field of vim.g.<x> operates on a copy and is lost, so read the table
          -- into a local, extend it, and assign the whole table back. Keep the
          -- per-ft value a plain list (vim.g cannot serialize a mixed
          -- list/dict table) -- "run first available" comes from conform's
          -- global stop_after_first set in the editor's conform.setup.
          local conform_fts = vim.g.conform_formatters_by_ft or {}
          local prettier = { "prettierd", "prettier" }
          for _, ft in ipairs({
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "json",
            "jsonc",
          }) do
            conform_fts[ft] = prettier
          end
          vim.g.conform_formatters_by_ft = conform_fts

          vim.lsp.config.ts_ls = {
            cmd = { "${pkgs.typescript-language-server}/bin/typescript-language-server", "--stdio" },
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
            },
            root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
          }
          vim.lsp.enable("ts_ls")
        ''
        + lib.optionalString cfg.eslint ''
          vim.lsp.config.eslint = {
            cmd = { "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server", "--stdio" },
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
            },
            root_markers = {
              ".eslintrc",
              ".eslintrc.js",
              ".eslintrc.cjs",
              ".eslintrc.json",
              ".eslintrc.yaml",
              "eslint.config.js",
              "eslint.config.mjs",
              "eslint.config.cjs",
              "eslint.config.ts",
            },
            -- eslint server fills sensible defaults for unspecified settings and
            -- auto-detects flat vs legacy config; "auto" working dir helps monorepos.
            settings = {
              workingDirectory = { mode = "auto" },
            },
          }
          vim.lsp.enable("eslint")
        ''
      );
    };
  };
}
