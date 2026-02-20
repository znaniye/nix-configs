{
  config,
  lib,
  pkgs,
  ...
}:

let
  GOPATH = "${config.home.homeDirectory}/.go";
  GOBIN = "${GOPATH}/bin";
in
{
  options.home-manager.dev.go.enable = lib.mkEnableOption "Go config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.go.enable {
    programs.go = {
      enable = true;
      env = { inherit GOBIN GOPATH; };
    };

    home = {
      packages = with pkgs; [ gopls ];
      sessionPath = [ GOBIN ];
    };

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [ pkgs.gopls ];
      plugins = lib.mkAfter (with pkgs.vimPlugins; [ vim-go ]);
      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.gopls = {
          cmd = { "${pkgs.gopls}/bin/gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          root_markers = { "go.work", "go.mod", ".git" },
        }
        vim.lsp.enable("gopls")
      '';
    };
  };
}
