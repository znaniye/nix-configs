{ config, lib, ... }:
{
  imports = [
    ./cloudflared.nix
    ./comin.nix
    ./emit.nix
    ./gitea.nix
    ./openssh.nix
    ./pi-hole.nix
  ];

  options.nixos.server = {
    enable = lib.mkEnableOption "servers common config" // {
      default = false;
    };
  };

  config = lib.mkIf config.nixos.server.enable {
    programs.zsh.enable = true;
  };
}
