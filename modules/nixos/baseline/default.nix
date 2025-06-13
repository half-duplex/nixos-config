{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.strings) concatStringsSep;
in {
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = ["tok/UTF-8" "eo/UTF-8"];
  i18n.extraLocaleSettings = {LC_TIME = "C.UTF-8";};

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
        rebootForBitlocker = true;
      };
      timeout = lib.mkDefault 1;
    };
    initrd.systemd.enable = true;
    # load modules before a service/mount has to wait for it
    kernelModules = [
      "efi_pstore"
      "nft_chain_nat"
      "nft_compat"
      "nft_ct"
      "nft_fib_inet"
      "nft_log"
      "xt_nat"
      "xt_mark"
      "xt_MASQUERADE"
      "xt_tcpudp"
    ];
    extraModprobeConfig = ''
      options kvm_amd nested=1
      options kvm_intel nested=1
    '';

    zfs.forceImportAll = false;
    zfs.forceImportRoot = false;
    # Others should be auto-loaded once tank is mounted
    zfs.requestEncryptionCredentials = ["tank" "pool"];

    kernelPackages = pkgs.linuxPackages_hardened;
    # If hardened is ever newer than ZFS supports:
    #kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    # Hardening based on a website by someone I do not wish to promote. 2022-03-21
    # and https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/hardened.nix 2022-03-21

    kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.printk" = "3 3 3 3";
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.ftrace_enabled" = 0;
      "dev.tty.ldisc_autoload" = 0;
      "vm.unprivileged_userfaultfd" = 0;
      "kernel.kexec_load_disabled" = 1;
      "kernel.sysrq" = 20; # SAK+sync
      #"kernel.unprivileged_userns_clone" = 0;  # Required by flatpak
      "kernel.perf_event_paranoid" = 3;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.tcp_sack" = 0;
      "net.ipv4.tcp_dsack" = 0;
      "kernel.yama.ptrace_scope" = 2;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;

      # x86. may differ on other architectures. FIXME only apply on x86
      # TODO add other archs
      "vm.mmap_rnd_bits" = 32;
      "vm.mmap_rnd_compat_bits" = 16;

      # https://cmm.github.io/soapbox/the-year-of-linux-on-the-desktop.html
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.watermark_boost_factor" = 0;
    };

    kernelParams = [
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      #"debugfs=off"
      "debugfs=on"
      "oops=panic" # Too strong?
      #"module.sig_enforce=1"
      #"lockdown=confidentiality"
      #"mce=0"
      "quiet"
      #"loglevel=0"
      "intel_iommu=on" # Having both OK
      "efi=disable_early_pci_dma"

      # TODO apply per-machine based on cpu
      #"spectre_v2=on"
      #"spec_store_bypass_disable=on"
      #"tsx=off"
      #"tsx_async_abort=full,nosmt"
      #"mds=full,nosmt"
      #"l1tf=full,force"
      #"nosmt=force"
      #"kvm.nx_huge_pages=force"
    ];
    blacklistedKernelModules = [
      "adfs"
      "af_802154"
      "affs"
      "appletalk"
      "atm"
      "ax25"
      "befs"
      "bfs"
      "can"
      "dccp"
      "decnet"
      "econet"
      "efs"
      "exofs"
      "freevxfs"
      "gfs2"
      "hpfs"
      "ipx"
      "jfs"
      "minix"
      "netrom"
      "nfsv2"
      "nfsv3"
      "n-hdlc"
      "nilfs2"
      "omfs"
      "p8022"
      "p8023"
      "psnap"
      "qnx4"
      "qnx6"
      "rds"
      "rose"
      "sctp"
      "sysv"
      "tipc"
      "ufs"
      "vivid"
      "firewire-core"
      "thunderbolt"
    ];
  };

  system.etc.overlay.enable = true;

  #environment.memoryAllocator.provider = "graphene-hardened"; # Breaks everything... ??
  #environment.memoryAllocator.provider = "scudo"; # Breaks firefox...
  #environment.variables.SCUDO_OPTIONS = "ZeroContents=1";
  #security.lockKernelModules = true;
  security.protectKernelImage = true; # kernel.kexec_load_disabled=1 and nohibernate
  #security.forcePageTableIsolation = true;
  security.unprivilegedUsernsClone = true;
  security.virtualisation.flushL1DataCache = "always";
  security.apparmor.enable = true;
  security.apparmor.killUnconfinedConfinables = true;
  security.sudo.execWheelOnly = lib.mkDefault true;
  security.krb5 = {
    enable = true;
    settings = {
      domain_realm = {
        "sec.gd" = "SEC.GD";
        ".sec.gd" = "SEC.GD";
      };
      libdefaults = {
        default_realm = "SEC.GD";
        permitted_enctypes = concatStringsSep " " [
          "aes256-cts-hmac-sha384-192"
          "aes128-cts-hmac-sha256-128"
          "aes256-cts-hmac-sha1-96"
          "aes128-cts-hmac-sha1-96"
        ];
        rdns = false;
        spake_preauth_groups = "edwards25519";
      };
      realms = {
        "SEC.GD" = {
          kdc = "kerberos.sec.gd";
          admin_server = "kerberos.sec.gd";
          default_principal_flags = "+preauth";
          disable_encrypted_timestamp = true;
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "e /nix/var/log - - - 30d"
  ];

  zramSwap.enable = true;

  # Filesystems
  systemd.services.zfs-mount.enable = false;
  services = {
    journald.extraConfig = "MaxRetentionSec=7d";
    udev.extraRules = ''
      SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs3"
    '';
    zfs = {
      autoScrub.enable = lib.mkDefault true;
      trim.enable = true;
      zed.settings.ZED_SYSLOG_SUBCLASS_EXCLUDE = "history_event";
    };
    zrepl = {
      enable = true;
      settings = {
        jobs = [
          {
            name = "tank_snap_nobackup";
            type = "snap";
            filesystems = {
              #"tank/nix<" = true;
              "tank/home/nobackup" = true;
              "tank/persist/nobackup<" = true;
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
            name = "tank_snap";
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
              "tank<" = true;
              "tank/nix<" = false;
              "tank/home/nobackup" = false;
              "tank/persist/nobackup<" = false;
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
    };
  };

  networking = {
    # with mkDefault, build claims this is set to null in nixpkgs/flake.nix??
    domain = lib.mkOverride 900 "sec.gd";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);
    hosts =
      lib.mkIf
      (
        config.networking.domain
        == "sec.gd"
        && config.services.tailscale.enable == true
      )
      {
        "100.64.0.2" = ["nova.sec.gd" "nova"];
        "100.64.0.3" = ["awdbox.sec.gd" "awdbox"];
        "100.64.0.5" = ["t14s.sec.gd" "t14s"];
        "100.64.0.7" = ["awen.sec.gd" "awen"];
      };
    nftables.enable = true;
    wireguard.enable = true;
  };

  nix = {
    package = lib.mkOverride 900 pkgs.lix; # ~Default, but override nixpkgs
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      allowed-users = ["@wheel"];
      auto-optimise-store = true;
    };
  };
  nixpkgs.config = {
    allowUnfree = true;
  };

  users = {
    groups = {
      adbusers = {};
      ssh-users = {};
    };
    users = {
      root = {
        extraGroups = ["ssh-users"];
      };
      mal = {
        isNormalUser = true;
        extraGroups = ["wheel" "ssh-users" "audio" "video" "networkmanager" "dialout" "input" "wireshark" "libvirtd"];
      };
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
    libvirtd = {
      parallelShutdown = 2;
      qemu = {
        runAsRoot = false;
        swtpm.enable = true;
        ovmf.packages = [pkgs.OVMFFull.fd];
      };
    };
  };

  services = {
    tailscale = {
      enable = true;
      interfaceName = "ts0";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "nixacme@" + "sec.gd";
  };
}
