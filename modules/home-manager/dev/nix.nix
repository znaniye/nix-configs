{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.dev.nix;
in
{
  options.home-manager.dev.nix = {
    enable = lib.mkEnableOption "Nix config" // {
      default = config.home-manager.dev.enable;
    };
    languageServer = lib.mkOption {
      type = lib.types.enum [
        "nixd"
        "nil"
      ];
      description = "Nix language server.";
      default = "nil";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        nixpkgs-review
        nix-tree
        nix-update
        nurl
        nixfmt
        nix-output-monitor
        nvd
        statix
      ]
      ++ lib.optionals (cfg.languageServer == "nil") [ nil ]
      ++ lib.optionals (cfg.languageServer == "nixd") [ nixd ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages =
        lib.mkAfter
          (
            [ pkgs.nixfmt ]
            ++ lib.optionals (cfg.languageServer == "nil") [ pkgs.nil ]
            ++ lib.optionals (cfg.languageServer == "nixd") [ pkgs.nixd ]
          );

      plugins = lib.mkAfter (with pkgs.vimPlugins; [ vim-nix ]);

      extraLuaConfig = lib.mkAfter (
        ''
          vim.g.conform_formatters_by_ft = vim.g.conform_formatters_by_ft or {}
          vim.g.conform_formatters_by_ft.nix = { "nixfmt" }
        ''
        + (
          if cfg.languageServer == "nil" then
            ''
              vim.lsp.config.nil_ls = {
                cmd = { "${pkgs.nil}/bin/nil" },
                filetypes = { "nix" },
                root_markers = { "flake.nix", ".git" },
              }
              vim.lsp.enable("nil_ls")
            ''
          else
            ''
              vim.lsp.config.nixd = {
                cmd = { "${pkgs.nixd}/bin/nixd" },
                filetypes = { "nix" },
                root_markers = { "flake.nix", ".git" },
              }
              vim.lsp.enable("nixd")
            ''
        )
      );
    };
  };
}
