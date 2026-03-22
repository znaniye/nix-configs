{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev;
  llvmPkgs = pkgs.llvmPackages_latest or pkgs.llvmPackages;
  clangTools = pkgs.clang-tools or llvmPkgs.clang-tools;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
  opencodePlugins = import ./plugins {
    inherit lib notificationSound pkgs;
  };

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

    "elixir-ls" = mkLspCommand true [ "${pkgs.elixir-ls}/bin/elixir-ls" ];

    fsharp = mkLspCommand cfg.dotnet.enable [ "${pkgs.fsautocomplete}/bin/fsautocomplete" ];

    gopls = mkLspCommand cfg.go.enable [ "${pkgs.gopls}/bin/gopls" ];

    "lua-ls" = mkLspCommand cfg.lua.enable [ "${pkgs.lua-language-server}/bin/lua-language-server" ];

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
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ llmAgentsPkgs.openspec ];

    sops.secrets.exa-api-key = { };
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings =
        let
          file = path: "{file:${path}}";
        in
        {
          plugin = opencodePlugins.entries;

          lsp = lspConfig;

          mcp = {
            context7 = {
              type = "remote";
              url = "https://mcp.context7.com/mcp";
            };
            exa = {
              enabled = true;
              type = "remote";
              url = "https://mcp.exa.ai/mcp?exaApiKey=${file config.sops.secrets.exa-api-key.path}";
            };
            gh_grep = {
              type = "remote";
              url = "https://mcp.grep.app";
            };
            nixos = {
              command = [ "${pkgs.mcp-nixos}/bin/mcp-nixos" ];
              enabled = true;
              type = "local";
            };
          };
        };
    };
  };
}
