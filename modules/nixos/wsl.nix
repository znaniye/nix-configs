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
  imports = [ flake.inputs.nixos-wsl.nixosModules.wsl ];

  options.nixos.wsl = {
    enable = lib.mkEnableOption "WSL host config" // {
      default = false;
    };

    startMenuLaunchers = lib.mkEnableOption "WSL start menu launchers" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    wsl = {
      enable = true;
      defaultUser = config.meta.username;
      inherit (cfg) startMenuLaunchers;
    };

    programs.zsh.enable = true;
  };
}
