{ lib, ... }:
{
  sconfig = {
    dvorak = true;
    plasma = true;
    profile = "desktop";
    hardware = "physical";
  };

  boot.initrd.availableKernelModules = [ "nvme" ];
  hardware.cpu.amd.updateMicrocode = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKu0BzxhF9J7L/0CLDuheOZurqEjPo4uSAFHNHmBXa0 mal@nova.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIGpN/Enpx1FCRBqzDNYNN/QL94X4eAaPyvB+K9ekDg mal@xps"
  ];

  environment.persistence."/persist" = {
    directories = [
      "/home"
    ];
  };

  fileSystems = lib.foldl (a: b: a // b)
    {
      "/data" = rec {
        device = "/dev/mapper/${encrypted.label}";
        encrypted = {
          enable = true;
          blkDev = "UUID=bc600d0b-0248-4003-bcf9-0e16b989fee5";
          label = "data";
          keyFile = "/persist/etc/cryptsetup-keys.d/data.key";
        };
        options = [ "noatime" ];
      };
      "/home2" = rec {
        device = "/dev/mapper/${encrypted.label}";
        encrypted = {
          enable = true;
          blkDev = "UUID=53ac285c-cfba-4698-b0eb-988cb8cbdeea";
          label = "crypthome";
          keyFile = "/persist/etc/cryptsetup-keys.d/crypthome.key";
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

    system.stateVersion = "23.11";
}
