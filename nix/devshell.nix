{ pkgs, ... }:
pkgs.mkShell {
  packages = with pkgs; [
    vim
    nil
    nixfmt-rfc-style
    ripgrep
  ];
}
