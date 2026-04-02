{ lib, ... }:
{
  home.stateVersion = "24.05";

  targets.genericLinux.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
}
