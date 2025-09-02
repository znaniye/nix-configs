{
  config,
  lib,
  ...
}:
let
  cfg = config.nixos.desktop.virtualization;
in
{

  options.nixos.desktop.virtualization = {
    enable = lib.mkEnableOption "virtualization cfg" // {
      default = false;
    };

    vmConfig = lib.mkOption {
      type = lib.types.attrs;
      description = "Virtualization options.";
      default = {
        memorySize = 4096;
        cores = 4;
      };
    };

  };

  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    users.users.${config.meta.username}.extraGroups =
      lib.optional config.nixos.desktop.virtualization.enable "libvirtd"; # ++

    virtualisation = {
      vmVariant.virtualisation = cfg.vmConfig;
      vmVariantWithBootLoader.virtualisation = cfg.vmConfig;
    };
  };
}
