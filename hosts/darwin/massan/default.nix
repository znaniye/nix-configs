{ ... }:
{
  shared.tailscale.enable = true;
  shared.fonts.enable = true;

  darwin.wireguard.enable = true;

  darwin.home.extraModules = {
    home-manager.editor.enable = true;
    home-manager.desktop.herdr.enable = true;
    home-manager.desktop.alacritty.enable = true;

    home-manager.dev = {
      typescript.enable = true;
    };
  };
}
