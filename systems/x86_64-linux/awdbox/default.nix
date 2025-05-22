{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: {
  ${namespace} = {
    archetypes.desktop.enable = true;
    desktop.plasma.enable = true;
    dvorak = true;
    hardware = "physical";
    remoteUnlock.enable = true;
    boot.secureboot.enable = true;
    services = {
      nut = {
        enable = true;
        localCyberPower = true;
        users.hass.passwordFile = config.sops.secrets."nut_password_hass".path;
      };
    };
  };

  boot = {
    initrd.kernelModules = ["nvme" "e1000e"];
    initrd.availableKernelModules = ["amdgpu"];
    kernelParams = [
      "ip=10.0.0.22::10.0.0.1:255.255.255.0::eth0:off:10.0.0.1"
      "processor.max_cstate=5"
      "amd_pstate=active"
    ];
    kernelModules = ["i2c-dev"]; # for DDC
  };
  console.earlySetup = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.rasdaemon.enable = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKu0BzxhF9J7L/0CLDuheOZurqEjPo4uSAFHNHmBXa0 mal@nova"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8CzUQOCHIXBPVrjt9uq417h/zAyBN+hfS/Yh56CX/b mal@awen"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/86ZJNimLxLqf+vVG5iINzfhdu98PtsMOZicorzWMQ mal@t14s"
  ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Canon-Pixma-TR4520-WiFi";
        deviceUri = "ipp://956151000000.local:631/ipp/print";
        model = "everywhere";
        ppdOptions = {
          Duplex = "DuplexNoTumble";
          PageSize = "US Letter";
        };
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    immich-go
    simple-scan
    virtio-win
  ];

  fileSystems =
    lib.foldl (a: b: a // b)
    {
      "/data" = {
        device = "pool/data";
        fsType = "zfs";
      };
      "/data/backups" = {
        device = "pool/backups";
        fsType = "zfs";
      };
      "/data/nobackup" = {
        device = "pool/nobackup";
        fsType = "zfs";
      };
      "/mnt/mars/data" = {
        device = "mars:/data";
        fsType = "nfs";
        options = ["noauto" "nfsvers=4" "sec=krb5p"];
      };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = ["noauto" "noatime"];
      };
    }));

  networking.firewall.allowedTCPPorts = [445];
  networking.interfaces.eth0.wakeOnLan.enable = true;
  services = {
    displayManager.defaultSession = lib.mkForce "plasmax11";
    ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      acceleration = "rocm";
      rocmOverrideGfx = "10.1.0";
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    postgresql = {
      enable = true;
      ensureDatabases = ["fuzzysearch"];
      authentication = ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
    };
    printing.enable = true;
    samba = {
      enable = true;
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = "%h";
          "passdb backend" = "tdbsam:/persist/etc/samba/private/passdb.tdb";
          "hosts deny" = "ALL";
          "hosts allow" = ["::1" "127.0.0.1" "10.0.0.0/16"];
          "logging" = "syslog";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "load printers" = "no";
          "disable spoolss" = "yes";
          "disable netbios" = "yes";
          "dns proxy" = "no";
          "inherit permissions" = "yes";
          "map to guest" = "Bad User";
          "client min protocol" = "SMB3";
          "server min protocol" = "SMB3";
          #"restrict anonymous" = 2;  # even =1 breaks anon from windows
          "smb ports" = 445;
          "client signing" = "desired";
          "client smb encrypt" = "desired";
          "server signing" = "desired";
          #"server smb encrypt" = "desired";  # breaks anon from windows
        };
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
    zrepl.settings.jobs = [
      {
        name = "data_snap_nobackup";
        type = "snap";
        filesystems = {
          "pool/nobackup" = true;
        };
        snapshotting = {
          type = "periodic";
          interval = "5m";
          prefix = "zrepl_";
        };
        pruning = {
          keep = [
            {
              type = "grid";
              grid = "1x1h(keep=all) | 32x15m | 24x1h";
              regex = "^zrepl_.*";
            }
            {
              type = "regex";
              negate = true;
              regex = "^zrepl_.*";
            }
          ];
        };
      }
      {
        name = "data_snap";
        type = "push";
        connect = {
          type = "ssh+stdinserver";
          host = "awen.sec.gd";
          #user = "zrepl";
          user = "root";
          port = 22;
          identity_file = "/persist/zrepl/ssh_awen";
          options = ["ControlMaster=no"];
        };
        send.encrypted = true;
        replication.protection = {
          initial = "guarantee_resumability";
          incremental = "guarantee_incremental";
        };
        filesystems = {
          "pool<" = true;
          "pool/nobackup<" = false;
        };
        snapshotting = {
          type = "periodic";
          interval = "5m";
          prefix = "zrepl_";
        };
        pruning = {
          keep_sender = [
            {type = "not_replicated";}
            {
              type = "grid";
              grid = "1x1h(keep=all) | 32x15m | 24x1h | 7x1d";
              regex = "^zrepl_.*";
            }
            {
              type = "regex";
              negate = true;
              regex = "^zrepl_.*";
            }
          ];
          keep_receiver = [
            {
              type = "grid";
              grid = "1x1d(keep=all) | 96x15m | 72x1h | 30x1d | 52x1w";
              regex = "^zrepl_.*";
            }
            {
              type = "regex";
              negate = true;
              regex = "^zrepl_.*";
            }
          ];
        };
      }
    ];
  };
  systemd.services.ensure-printers.wantedBy = lib.mkForce []; # fails if printer off
  systemd.services.ollama.wantedBy = lib.mkForce [];
  systemd.services.postgresql.wantedBy = lib.mkForce [];

  programs.gnupg.agent.enable = true;

  system.stateVersion = "25.05";
}
