{ ... }:
{
  shared.tailscale.enable = true;
  shared.fonts.enable = true;

  darwin.home.extraModules = {
    home-manager.dev = {
      typescript.enable = true;
    };
  };
}
