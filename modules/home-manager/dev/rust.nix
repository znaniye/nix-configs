{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.dev.rust.enable = lib.mkEnableOption "Rust config" // {
    default = config.home-manager.dev.enable;
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
  };
}
