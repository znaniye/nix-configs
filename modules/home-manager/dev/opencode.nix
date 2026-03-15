{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev;
  llvmPkgs = pkgs.llvmPackages_latest or pkgs.llvmPackages;
  clangTools = pkgs.clang-tools or llvmPkgs.clang-tools;

  mkLspCommand = enabled: command: if enabled then { inherit command; } else { disabled = true; };

  mkLspConfig = enabled: options: if enabled then options else { disabled = true; };

  lspConfig = {
    bash = {
      command = [
        "${pkgs.bash-language-server}/bin/bash-language-server"
        "start"
      ];
    };

    clangd = mkLspCommand cfg.cc.enable [ "${clangTools}/bin/clangd" ];

    csharp = mkLspCommand cfg.dotnet.enable [ "${pkgs.csharp-ls}/bin/csharp-ls" ];

    fsharp = mkLspCommand cfg.dotnet.enable [ "${pkgs.fsautocomplete}/bin/fsautocomplete" ];

    "elixir-ls" = mkLspCommand true [ "${pkgs.elixir-ls}/bin/elixir-ls" ];

    gopls = mkLspCommand cfg.go.enable [ "${pkgs.gopls}/bin/gopls" ];

    "lua-ls" = mkLspCommand cfg.lua.enable [ "${pkgs.lua-language-server}/bin/lua-language-server" ];

    nil = mkLspConfig (cfg.nix.enable && cfg.nix.languageServer == "nil") {
      command = [ "${pkgs.nil}/bin/nil" ];
      extensions = [ ".nix" ];
    };

    nixd = mkLspCommand (cfg.nix.enable && cfg.nix.languageServer == "nixd") [
      "${pkgs.nixd}/bin/nixd"
    ];

    "ocaml-lsp" = mkLspCommand cfg.ocaml.enable [ "${pkgs.ocamlPackages.ocaml-lsp}/bin/ocamllsp" ];

    pyright = mkLspCommand cfg.python.enable [
      "${pkgs.pyright}/bin/pyright-langserver"
      "--stdio"
    ];

    rust = mkLspCommand cfg.rust.enable [ "${pkgs.rust-analyzer}/bin/rust-analyzer" ];

    zls = mkLspCommand cfg.zig.enable [ "${pkgs.zls}/bin/zls" ];

    marksman = {
      command = [
        "${pkgs.marksman}/bin/marksman"
        "server"
      ];
      extensions = [
        ".markdown"
        ".md"
        ".mdx"
      ];
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      lsp = lspConfig;
    };
  };
}
