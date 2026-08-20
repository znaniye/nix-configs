prefix:
{
  config,
  flake,
  lib,
  libEx,
  ...
}:
let
  cfg = config.${prefix}.home;
  cfgHome = config.home-manager.users.${cfg.username};
in
{
  config = lib.mkIf cfg.enable {
    # Home-Manager standalone already adds home-manager to PATH, so we
    # are adding here only for NixOS
    environment.systemPackages = [
      cfgHome.programs.home-manager.package
    ];

    home-manager = {
      backupFileExtension = lib.mkDefault "backup";
      extraSpecialArgs = { inherit flake libEx; };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${cfg.username} = {
        home-manager = {
          inherit (config.networking) hostName;
        };
        imports = [ flake.outputs.homeModules.default ] ++ cfg.extraModules;
        shared = { inherit (config.shared) meta theme; };
      };
    };
  };
  options.${prefix}.home = {
    enable = lib.mkEnableOption "home config" // {
      default = true;
    };
    extraModules = lib.mkOption {
      default = [ ];
      description = "Extra modules to import.";
      type = with lib.types; coercedTo attrs (x: [ x ]) (listOf attrs);
    };
    restoreBackups = lib.mkEnableOption "restore backup files before activation";
    username = lib.mkOption {
      default = "znaniye";
      description = "Main username.";
      type = lib.types.str;
    };
  };
}
