{ lib, pkgs, ... }:
{
  sconfig = {
    dvorak = true;
    plasma = true;
    profile = "desktop";
    hardware = "physical";
    secureboot = true;
  };

  boot.initrd.availableKernelModules = [ "nvme" ];
  hardware.cpu.amd.updateMicrocode = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIt2xxDXFBkIOODdasb1v0253kZqUa8UydrLCOtffQot mal@awdbox"
  ];

  fileSystems = lib.foldl (a: b: a // b)
    {
      "/home" = { device = "tank/home"; fsType = "zfs"; };
      "/mnt/awdbox/data" = {
        device = "awdbox:/data";
        fsType = "nfs";
        options = [ "noauto" "nfsvers=4" "sec=krb5p" ];
      };
      "/mnt/mars/data" = {
        device = "mars:/data";
        fsType = "nfs";
        options = [ "noauto" "nfsvers=4" "sec=krb5p" ];
      };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = [ "noauto" "noatime" ];
      };
    }));

    services = {
      avahi.enable = true;
      tor = {
        enable = true;
        client.enable = true;
      };
      zfs.autoScrub.enable = false;  # battery
    };

    programs.gnupg.agent.enable = true;

    system.stateVersion = "23.11";
}
