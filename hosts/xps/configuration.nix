{ lib, pkgs, ... }:
{
  sconfig = {
    dvorak = true;
    plasma = true;
    profile = "desktop";
    hardware = "physical";
    #security-tools = true;
  };

  boot.initrd.availableKernelModules = [ "nvme" ];
  hardware.cpu.intel.updateMicrocode = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYenMcXumgnwcAVa40KGhyXX3/VPqIZ9/YIej3g+RMC mal@luca.sec.gd"
  ];

  # HiDPI
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-v22n.psf.gz";
  console.earlySetup = true;
  boot.loader.systemd-boot.consoleMode = "1";
  services.xserver.dpi = 192;

  # Battery
  services.zfs.autoScrub.enable = false;

  environment.persistence."/persist" = {
    directories = [
      "/home"
    ];
  };

  fileSystems = lib.foldl (a: b: a // b)
    {
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

  system.stateVersion = "23.05";
}
