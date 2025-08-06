{
  config,
  lib,
  ...
}:
{

  options.nixos.desktop.virtualization.enable = lib.mkEnableOption "virtualization cfg" // {
    default = false;
  };

  config = lib.mkIf config.nixos.desktop.virtualization.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    users.users.${config.meta.username}.extraGroups =
      lib.optional config.nixos.desktop.virtualization.enable "libvirtd"; # ++
  };
}
