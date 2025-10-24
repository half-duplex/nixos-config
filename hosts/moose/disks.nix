{
  inputs,
  lib,
  ...
}: let
  inherit (lib) genAttrs;
in {
  imports = [
    inputs.disko.nixosModules.default
  ];

  disko.devices = {
    disk.sdcard = {
      type = "disk";
      device = "/dev/mmcblk0";
      content = {
        type = "gpt";
        partitions = {
          firmware = {
            label = "firmware";
            priority = 1;
            type = "0700"; # = Microsoft basic data
            attributes = [0]; # = required
            size = "1024M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountOptions = [
                # TODO: needed?
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
              ];
            };
          };
          boot = {
            label = "_esp";
            priority = 150;
            type = "EF00"; # = ESP
            attributes = [2]; # = bootable
            size = "1024M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                # TODO: needed?
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
                "umask=0077" # protect /boot/loader/random-seed
              ];
            };
          };
          zfs = {
            label = "tank-moose";
            size = "100%";
            content = {
              type = "zfs";
              pool = "tank";
            };
          };
          swap = {
            label = "swap";
            start = "-8G";
            end = "-0";
            content = {
              type = "swap";
              discardPolicy = "both";
              randomEncryption = true;
            };
          };
        };
      };
    };
    zpool.tank = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        canmount = "off";
        compression = "zstd-1";
        dnodesize = "auto";
        encryption = "on";
        keyformat = "passphrase";
        keylocation = "prompt";
        mountpoint = "none";
        normalization = "formD";
        xattr = "sa";
      };
      datasets =
        (genAttrs [
            "home"
            "home/nobackup"
            "nix"
            "persist"
            "persist/nobackup"
          ] (dataset: {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/${dataset}";
          }))
        // {
          ## https://github.com/openzfs/zfs/issues/7734
          #"swap" = {
          #  type = "zfs_volume";
          #  size = "4G";
          #  content.type = "swap";
          #  options = {
          #    volblocksize = "4096"; # `getconf PAGESIZE`
          #    logbias = "throughput";
          #    sync = "always";
          #    primarycache = "metadata";
          #    secondarycache = "none";
          #    "com.sun:auto-snapshot" = "false";
          #  };
          #};
        };
    };
  };
}
