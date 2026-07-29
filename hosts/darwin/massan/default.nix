{ ... }:
{
  darwin.desktop.enable = true;

  darwin.home.extraModules = {
    home-manager.dev = {
      typescript.enable = true;
    };
  };
}
