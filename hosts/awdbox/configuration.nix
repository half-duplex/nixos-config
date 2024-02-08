{ lib, pkgs, ... }:
{
  sconfig = {
    dvorak = true;
    plasma = true;
    profile = "desktop";
    hardware = "physical";
    remoteUnlock = true;
  };

  boot.initrd.availableKernelModules = [ "nvme" "r8169" ];
  boot.kernelParams = [ "ip=10.0.0.22::10.0.0.1:255.255.255.0::eth0:none" "processor.max_cstate=5" ];
  console.earlySetup = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.rasdaemon.enable = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKu0BzxhF9J7L/0CLDuheOZurqEjPo4uSAFHNHmBXa0 mal@nova.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIGpN/Enpx1FCRBqzDNYNN/QL94X4eAaPyvB+K9ekDg mal@xps"
  ];

  fileSystems = lib.foldl (a: b: a // b)
    {
      "/home" = { device = "tank/home"; fsType = "zfs"; };
      "/data" = { device = "awdbox-data/data"; fsType = "zfs"; };
      "/data/backups" = { device = "awdbox-data/backups"; fsType = "zfs"; };
      "/data/steam" = { device = "awdbox-data/steam"; fsType = "zfs"; };
      "/home2" = rec {
        device = "/dev/mapper/${encrypted.label}";
        encrypted = {
          enable = true;
          blkDev = "/dev/disk/by-uuid/53ac285c-cfba-4698-b0eb-988cb8cbdeea";
          label = "crypthome";
          keyFile = "/mnt-root/persist/etc/cryptsetup-keys.d/crypthome.key";
        };
        options = [ "noatime" ];
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

    programs.gnupg.agent.enable = true;

    system.stateVersion = "23.11";
}
