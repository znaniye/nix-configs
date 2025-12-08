{
  config,
  lib,
  ...
}:

{

  options.nixos.server.comin.enable = lib.mkEnableOption "comin config" // {
    default = config.nixos.server.enable;
  };

  config = lib.mkIf config.nixos.server.comin.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/znaniye/nix-configs.git";
          branches.testing.name = "master";
        }
      ];
    };
  };
}
