{
  config,
  flake,
  lib,
  ...
}:

{
  config = lib.mkIf config.nixos.server.comin.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          auth = {
            access_token_path = config.sops.secrets.gitea-pat-token.path;
            username = "znaniye";
          };
          branches.main.name = "master";
          name = "origin";
          url = "http://192.168.68.111:3000/znaniye/nix-configs.git";
        }
      ];
    };
  };
  imports = [ flake.inputs.comin.nixosModules.comin ];
  options.nixos.server.comin.enable = lib.mkEnableOption "comin config" // {
    default = config.nixos.server.enable;
  };
}
