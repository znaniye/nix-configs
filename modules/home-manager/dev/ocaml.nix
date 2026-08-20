{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home-manager.dev.ocaml.enable {

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.ocamllsp = {
          cmd = { "${pkgs.ocamlPackages.ocaml-lsp}/bin/ocamllsp" },
          filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex", "reason", "dune" },
          root_markers = { "*.opam", "esy.json", "package.json", ".git", "dune-project", "dune-workspace" },
        }
        vim.lsp.enable("ocamllsp")
      '';
      extraPackages = lib.mkAfter [ pkgs.ocamlPackages.ocaml-lsp ];
    };
  };
  options.home-manager.dev.ocaml.enable = lib.mkEnableOption "ocaml config" // {
    default = false;
  };
}
