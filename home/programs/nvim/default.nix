{ pkgs, ... }:
{
  imports = [
    ./lsp.nix
    ./ui.nix
  ];

  home.sessionVariables.EDITOR = "nvim";
  programs.neovim = {
    enable = true;

    extraLuaConfig = builtins.readFile ./config.lua;

    plugins = with pkgs.vimPlugins; [
      markdown-preview-nvim
      {
        plugin = nvim-autopairs;
        type = "lua";
        config =
          # lua
          ''
            require('nvim-autopairs').setup{}
          '';
      }
    ];
  };
}
