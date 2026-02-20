{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.glsl.enable = lib.mkEnableOption "GLSL dev" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.glsl.enable {
    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      plugins = lib.mkAfter (with pkgs.vimPlugins; [ vim-glsl ]);
    };
  };
}

