{ ... }:
{
  darwin.desktop.enable = true;
  darwin.desktop.syncthing.enable = true;

  darwin.home.extraModules = {
    home-manager.dev = {
      typescript.enable = true;
    };
  };
}
