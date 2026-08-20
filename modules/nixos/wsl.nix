{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.nixos.wsl;
in
{
  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;
    wsl = {
      inherit (cfg) startMenuLaunchers;
      defaultUser = config.shared.meta.username;
      enable = true;
    };
  };
  imports = [ flake.inputs.nixos-wsl.nixosModules.wsl ];
  options.nixos.wsl = {
    enable = lib.mkEnableOption "WSL host config" // {
      default = false;
    };

    startMenuLaunchers = lib.mkEnableOption "WSL start menu launchers" // {
      default = true;
    };
  };
}
