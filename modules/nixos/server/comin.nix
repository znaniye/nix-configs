{
  config,
  flake,
  lib,
  ...
}:

{
  imports = [ flake.inputs.comin.nixosModules.comin ];

  options.nixos.server.comin.enable = lib.mkEnableOption "comin config" // {
    default = config.nixos.server.enable;
  };

  config = lib.mkIf config.nixos.server.comin.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "http://192.168.68.111:3000/znaniye/nix-configs.git";
          auth = {
            username = "znaniye";
            access_token_path = config.sops.secrets.gitea-pat-token.path;
          };
          branches.main.name = "master";
        }
      ];
    };
  };
}
