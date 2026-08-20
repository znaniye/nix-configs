{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home-manager.dev.elixir.enable {
    home.packages = with pkgs; [
      elixir
      erlang
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      plugins = lib.mkAfter (
        with pkgs.vimPlugins;
        [
          vim-elixir
          {
            config = ''
              require("elixir").setup()
            '';
            plugin = elixir-tools-nvim;
            type = "lua";
          }
        ]
      );
    };
  };
  options.home-manager.dev.elixir.enable = lib.mkEnableOption "Elixir dev" // {
    default = false;
  };
}
