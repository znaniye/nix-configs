{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home-manager.dev.zig.enable {
    home = {
      packages = with pkgs; [
        zig
        zls
      ];
    };

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.zls = {
          cmd = { "${pkgs.zls}/bin/zls" },
          root_markers = { "build.zig", ".git" },
          filetypes = { "zig" },
        }
        vim.lsp.enable("zls")
      '';
      extraPackages = lib.mkAfter [ pkgs.zls ];
    };
  };
  options.home-manager.dev.zig.enable = lib.mkEnableOption "zig config" // {
    default = false;
  };
}
