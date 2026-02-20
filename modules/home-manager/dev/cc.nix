{
  config,
  lib,
  pkgs,
  ...
}:

let
  llvmPkgs = pkgs.llvmPackages_latest or pkgs.llvmPackages;
  clangTools = pkgs.clang-tools or llvmPkgs.clang-tools;
in
{
  options.home-manager.dev.cc.enable = lib.mkEnableOption "C/C++ dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.cc.enable {
    home.packages = [
      clangTools
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [ clangTools ];
      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.clangd = {
          cmd = { "${clangTools}/bin/clangd" },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
          root_markers = {
            "compile_commands.json",
            "compile_flags.txt",
            ".git",
            "CMakeLists.txt",
            "Makefile",
            "meson.build",
          },
        }

        vim.lsp.enable("clangd")
      '';
    };
  };
}

