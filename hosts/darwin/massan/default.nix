{ ... }:
{
  shared.tailscale.enable = true;
  shared.fonts.enable = true;

  darwin.wireguard.enable = true;
  darwin.openssh.enable = true;

  users.users.znaniye.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbJhk5H0h7Oi79LSHLWfuffv6uFcuXtm77kewxrwQsD znaniye@golf"
  ];

  darwin.home.extraModules = {
    home-manager.editor.enable = true;
    home-manager.desktop.herdr.enable = true;
    home-manager.desktop.alacritty.enable = true;

    home-manager.dev = {
      typescript.enable = true;
    };
  };
}
