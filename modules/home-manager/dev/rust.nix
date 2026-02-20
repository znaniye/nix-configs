{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.rust.enable = lib.mkEnableOption "Rust config" // {
    default = false;
  };

  config = lib.mkIf config.home-manager.dev.rust.enable {
    home = {
      packages = with pkgs; [
        cargo
        rustc
        rust-analyzer
        rustfmt
      ];
    };

    programs.neovim = lib.mkIf config.home-manager.editor.nvim.enable {
      extraPackages = lib.mkAfter [
        pkgs.rust-analyzer
        pkgs.rustfmt
      ];

      plugins = lib.mkAfter (with pkgs.vimPlugins; [
        {
          plugin = rustaceanvim;
          type = "lua";
          config = '''';
        }
      ]);
    };
  };
}
