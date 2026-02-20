{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.home-manager.dev.python.enable = lib.mkEnableOption "Python config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.python.enable {
    home.packages = with pkgs; [
      pyright
      python3
      ruff
      uv
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [ pkgs.pyright ];
      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.pyright = {
          cmd = { "${pkgs.pyright}/bin/pyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py" },
        }
        vim.lsp.enable("pyright")
      '';
    };
  };
}
