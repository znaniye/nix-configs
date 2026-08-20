{ lib, ... }:
let
  firmwarePartition = lib.recursiveUpdate {
    attributes = [
      0 # Required Partition
    ];
    content = {
      format = "vfat";
      mountOptions = [
        "noatime"
      ];
      type = "filesystem";
    };
    priority = 1;
    size = "1024M";
    type = "0700"; # Microsoft basic data
  };

  espPartition = lib.recursiveUpdate {
    attributes = [
      2 # Legacy BIOS Bootable, for U-Boot to find extlinux config
    ];
    content = {
      format = "vfat";
      mountOptions = [
        "noatime"
        "umask=0077"
      ];
      type = "filesystem";
    };
    size = "1024M";
    type = "EF00"; # EFI System Partition (ESP)
  };

in
{
  disko.devices = {
    disk.nvme0 = {
      content = {
        partitions = {

          ESP = espPartition {
            content.mountpoint = "/boot";
            label = "ESP";
          };
          FIRMWARE = firmwarePartition {
            content.mountpoint = "/boot/firmware";
            label = "FIRMWARE";
          };
          root = {
            content = {
              format = "ext4";
              mountOptions = [
                "defaults"
                "x-systemd.growfs"
              ];
              mountpoint = "/";
              type = "filesystem";
            };
            label = "ROOT";
            size = "100%";
          };
        };
        type = "gpt";
      };
      device = "/dev/nvme0n1";
      type = "disk";
    };
  };
}
