{
  config,
  flake,
  hostName,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = with flake.modules.nixos; [
    (modulesPath + "/installer/scan/not-detected.nix")
    base
    desktop
    plasma
    samba
    ups
  ];

  mal = {
    hardware = "physical";
    nix-cache.serve.enable = true;
    services = {
      nut = {
        enable = true;
        localCyberPower = true;
        users.hass.passwordFile = config.sops.secrets."nut_password_hass".path;
      };
      samba = {
        enable = true;
        discoverable = true;
      };
    };
  };

  boot = {
    initrd.kernelModules = ["nvme" "e1000e"];
    initrd.availableKernelModules = ["amdgpu"];
    kernelParams = [
      "ip=10.0.0.22::10.0.0.1:255.255.255.0::eth0:off:10.0.0.1"
      "amd_pstate=active"
      "amdgpu.ppfeaturemask=0xfff7ffff"
    ];
    kernelModules = ["i2c-dev"]; # for DDC
    kernelPackages = lib.mkForce pkgs.linuxPackages;
  };
  console.earlySetup = true;

  hardware = {
    amdgpu.opencl.enable = true;
    cpu.amd.updateMicrocode = true;
    rasdaemon.enable = true;

    # Needed for Resolve
    graphics.extraPackages = with pkgs; [rocmPackages.clr.icd];

    keyboard.qmk.enable = true;
    printers = {
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
  };

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKu0BzxhF9J7L/0CLDuheOZurqEjPo4uSAFHNHmBXa0 mal@nova"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8CzUQOCHIXBPVrjt9uq417h/zAyBN+hfS/Yh56CX/b mal@awen"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/86ZJNimLxLqf+vVG5iINzfhdu98PtsMOZicorzWMQ mal@t14s"
  ];

  environment.systemPackages = with pkgs; [
    immich-go
    simple-scan
    qmk
    qmk_hid

    (writeShellApplication {
      name = "bright";
      runtimeInputs = with pkgs; [ddcutil];
      text = lib.strings.removePrefix "#!/usr/bin/env bash\nset -euo pipefail\n\n" (
        builtins.readFile ./bright.sh
      );
    })
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
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = ["noauto" "noatime"];
      };
    }));

  networking = {
    inherit hostName;
    firewall.allowedTCPPorts = [445];
    interfaces.eth0.wakeOnLan.enable = true;
  };
  services = {
    displayManager.defaultSession = lib.mkForce "plasmax11";
    ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      acceleration = "rocm";
      rocmOverrideGfx = "10.1.0";
    };
    openvpn.servers.commercial = {
      config = "config ${config.sops.secrets."openvpn_awdbox_commercial".path}";
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
    samba.settings = {
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

  sops.secrets."openvpn_awdbox_commercial".sopsFile = secrets/openvpn.yaml;

  systemd.services = {
    ensure-printers.wantedBy = lib.mkForce []; # fails if printer off
    ollama.wantedBy = lib.mkForce [];
    postgresql.wantedBy = lib.mkForce [];
  };

  programs.gnupg.agent.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
