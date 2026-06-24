{ config, lib, ... }:
{
  imports = [
    ./cloudflared.nix
    ./comin.nix
    #./emit.nix
    ./garnix.nix
    ./garnix-runner.nix
    ./gitea.nix
    ./opencode.nix
    ./openssh.nix
    ./pi-hole.nix
    ./solidtime.nix
  ];

  options.nixos.server = {
    enable = lib.mkEnableOption "servers common config" // {
      default = false;
    };
  };

  config = lib.mkIf config.nixos.server.enable {
    programs.zsh.enable = true;

    time.timeZone = lib.mkDefault "America/Sao_Paulo";
  };
}
