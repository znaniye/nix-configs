{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.dotnet.enable = lib.mkEnableOption "dotnet stuff" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.dotnet.enable {
    home.packages = with pkgs; [
      dotnet-sdk_10
      csharp-ls
      fsautocomplete
      fantomas
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [
        pkgs.csharp-ls
        pkgs.fsautocomplete
        pkgs.fantomas
      ];

      plugins = lib.mkAfter (with pkgs.vimPlugins; [ Ionide-vim ]);

      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.csharp_ls = {
          cmd = { "${pkgs.csharp-ls}/bin/csharp-ls" },
          filetypes = { "cs" },
          root_markers = { ".git" },
        }
        vim.lsp.enable("csharp_ls")
      '';
    };
  };
}
