{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.haskell.enable = lib.mkEnableOption "haskell dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.haskell.enable {
    home.packages = with pkgs; [
      ghc
    ];

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      plugins = lib.mkAfter (with pkgs.vimPlugins; [ haskell-tools-nvim ]);
    };
  };
}
