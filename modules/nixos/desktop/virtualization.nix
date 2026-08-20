{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.desktop.virtualization;
in
{

  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    programs.virt-manager.enable = true;
    users.users.${config.shared.meta.username}.extraGroups =
      lib.optional config.nixos.desktop.virtualization.enable "libvirtd"; # ++
    virtualisation = {
      vmVariant.virtualisation = cfg.vmConfig;
      vmVariantWithBootLoader.virtualisation = cfg.vmConfig;
    };
    virtualisation.libvirtd.enable = true;
  };
  options.nixos.desktop.virtualization = {
    enable = lib.mkEnableOption "virtualization cfg" // {
      default = false;
    };

    vmConfig = lib.mkOption {
      default = {
        cores = 4;
        memorySize = 4096;
      };
      description = "Virtualization options.";
      type = lib.types.attrs;
    };

  };
}
