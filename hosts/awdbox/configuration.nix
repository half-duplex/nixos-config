{ lib, pkgs, ... }:
{
  sconfig = {
    dvorak = true;
    plasma = true;
    profile = "desktop";
    hardware = "physical";
    remoteUnlock = true;
    secureboot = true;
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

  environment.systemPackages = with pkgs; [
     virtio-win
  ];

  fileSystems = lib.foldl (a: b: a // b)
    {
      "/data" = { device = "awdbox-data/data"; fsType = "zfs"; };
      "/data/backups" = { device = "awdbox-data/backups"; fsType = "zfs"; };
      "/data/nobackup" = { device = "awdbox-data/nobackup"; fsType = "zfs"; };
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

    networking.firewall.allowedTCPPorts = [ 445 ];
    services = {
      avahi.enable = true;
      samba = {
        enable = true;
        enableWinbindd = false;
        enableNmbd = false;
        extraConfig = ''
          server string = %h
          passdb backend = tdbsam:/persist/etc/samba/private/passdb.tdb
          hosts deny = ALL
          hosts allow = ::1 127.0.0.1 10.0.0.0/16
          logging = syslog
          printing = bsd
          printcap name = /dev/null
          load printers = no
          disable spoolss = yes
          disable netbios = yes
          dns proxy = no
          inherit permissions = yes
          map to guest = Bad User
          client min protocol = SMB3
          server min protocol = SMB3
          ;restrict anonymous = 2  ; even =1 breaks anon from windows
          smb ports = 445
          client signing = desired
          client smb encrypt = desired
          server signing = desired
          ;server smb encrypt = desired  ; breaks anon from windows
        '';
        shares = {
          homes = {
            browseable = "no";
            writeable = "yes";
            "valid users" = "%S";
          };
          public = {
            path = "/data/public";
            #writeable = "yes";
            public = "yes";
          };
          media = {
            path = "/data/library";
            writeable = "yes";
          };
        };
      };
      tor = {
        enable = true;
        client.enable = true;
      };
    };

    programs.gnupg.agent.enable = true;

    system.stateVersion = "23.11";
}
