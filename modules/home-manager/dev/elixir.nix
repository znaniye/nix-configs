{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.elixir.enable = lib.mkEnableOption "Elixir dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.elixir.enable {
    home.packages = with pkgs; [
      elixir
      erlang
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      plugins = lib.mkAfter (with pkgs.vimPlugins; [
        vim-elixir
        {
          plugin = elixir-tools-nvim;
          type = "lua";
          config = ''
            require("elixir").setup()
          '';
        }
      ]);
    };
  };
}

