{ pkgs, ... }:
{
  imports = [
    ./lsp.nix
    ./ui.nix
  ];

  home.sessionVariables.EDITOR = "nvim";
  programs.neovim = {
    enable = true;
   /* extraConfig = ''
      colorscheme gruvbox
      set number relativenumber
      set tabstop=4
      set shiftwidth=4
      set expandtab

      nnoremap <C-l> :bnext<CR>
      nnoremap <C-h> :bprevious<CR>
      nnoremap <C-y> :ToggleTerm direction=float size=40<CR>
    '';*/

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
