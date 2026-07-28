{
  config,
  lib,
  ...
}:

let
  cfg = config.darwin.nix;
in
{
  options.darwin.nix.enable = lib.mkEnableOption "nix/nixpkgs config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix = {
      gc = {
        automatic = true;
        interval = {
          Hour = 3;
          Minute = 15;
        };
        options = "--delete-older-than 30d";
      };

      settings.trusted-users = [ "@admin" ];
    };
  };
}
