{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./cc.nix
    ./dotnet.nix
    ./elixir.nix
    ./go.nix
    ./glsl.nix
    ./godot.nix
    ./haskell.nix
    ./lua.nix
    ./nix.nix
    ./ocaml.nix
    ./python.nix
    ./rust.nix
    ./zig.nix
  ];

  options.home-manager.dev.enable = lib.mkEnableOption "dev config" // {
    default = true;
  };

  config = lib.mkIf config.home-manager.dev.enable {
    home.packages = with pkgs; [
      bash-language-server
      expect
      marksman
      shellcheck
    ];

    programs = {

      direnv = {
        enable = true;
        enableZshIntegration = false;
      };

      neovim = lib.mkIf config.home-manager.editor.nvim.enable {
        extraPackages = lib.mkAfter [ pkgs.bash-language-server ];
        extraLuaConfig = lib.mkAfter ''
          vim.lsp.config.bash = {
            cmd = { "${pkgs.bash-language-server}/bin/bash-language-server", "start" },
            filetypes = { "sh", "bash", "zsh" },
          }
          vim.lsp.enable("bash")
        '';
      };

      tealdeer = {
        enable = true;
        settings = {
          display = {
            compact = false;
            use_pager = true;
          };
          updates = {
            auto_update = false;
          };
        };
      };

      zsh.initContent =
        # manually creating integrations since this is faster than calling
        # the `direnv hook zsh` itself during startup
        # bash
        ''
          source ${
            pkgs.runCommand "direnv-hook-zsh" { buildInputs = [ config.programs.direnv.package ]; } ''
              direnv hook zsh > $out
            ''
          }
        '';
    };
  };
}
