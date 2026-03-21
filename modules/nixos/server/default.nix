{ config, lib, ... }:
{
  imports = [
    ./cloudflared.nix
    ./openssh.nix
    ./emit.nix
    ./pi-hole.nix
    ./comin.nix
    ./gitea.nix
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
