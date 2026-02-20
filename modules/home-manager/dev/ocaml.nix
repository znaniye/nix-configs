{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.ocaml.enable = lib.mkEnableOption "ocaml config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.ocaml.enable {
    home.packages =
      (with pkgs; [
        ocaml
        ocamlformat_0_26_1
      ])
      ++ (with pkgs.ocamlPackages; [
        ocaml-lsp
        utop
      ]);

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [ pkgs.ocamlPackages.ocaml-lsp ];
      extraLuaConfig = lib.mkAfter ''
        vim.lsp.config.ocamllsp = {
          cmd = { "${pkgs.ocamlPackages.ocaml-lsp}/bin/ocamllsp" },
          filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex", "reason", "dune" },
          root_markers = { "*.opam", "esy.json", "package.json", ".git", "dune-project", "dune-workspace" },
        }
        vim.lsp.enable("ocamllsp")
      '';
    };
  };
}
