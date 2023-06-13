{ config, pkgs, lib, ... }:
{
  time.timeZone = "US/Eastern";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "eo/UTF-8" ];
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = { LC_TIME = "C"; };

  boot = {
    loader.systemd-boot.enable = true;
    loader.systemd-boot.editor = false;

    zfs.forceImportAll = false;
    zfs.forceImportRoot = false;

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
    };

    kernelParams = [
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "debugfs=off"
      "oops=panic" # Too strong?
      #"module.sig_enforce=1"
      #"lockdown=confidentiality"
      "mce=0"
      "quiet"
      "loglevel=0"
      "intel_iommu=on" # Having both OK
      "amd_iommu=on"
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
      "erofs"
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

  nix.settings.allowed-users = [ "@wheel" ];
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

  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  systemd.tmpfiles.rules = [
    "e /nix/var/log - - - 30d"
  ];

  zramSwap.enable = true;

  # ZFS
  systemd.services.zfs-mount.enable = false;
  services.zfs.autoScrub.enable = lib.mkDefault true;
  services.zfs.trim.enable = true;

  networking = {
    domain = lib.mkDefault "sec.gd";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);
    hosts = lib.mkIf
      (
        config.networking.domain == "sec.gd" &&
        config.services.tailscale.enable == true
      )
      {
        "100.64.0.1" = [ "xps.sec.gd" "xps" ];
        "100.64.0.2" = [ "nova.sec.gd" "nova" ];
        "100.64.0.3" = [ "awdbox.sec.gd" "awdbox" ];
        "100.64.0.4" = [ "mars.sec.gd" "mars" ];
      };
    wireguard.enable = true;
  };

  nix = {
    package = pkgs.nixFlakes;
    daemonCPUSchedPolicy = "idle";
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  users.groups.ssh-users = { };
  users.users.root.extraGroups = [ "ssh-users" ];
  users.users.mal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "ssh-users" "audio" "video" "networkmanager" "dialout" "input" "wireshark" "libvirtd" ];
  };

  virtualisation.docker = { enable = true; enableOnBoot = false; };
  virtualisation.libvirtd.qemu.runAsRoot = false;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    extraConfig = ''
      AllowGroups ssh-users
      GSSAPIAuthentication yes
    '';
  };

  services.tailscale = {
    enable = true;
    interfaceName = "ts0";
  };

  krb5 = {
    enable = true;
    domain_realm = {
      "sec.gd" = "SEC.GD";
      ".sec.gd" = "SEC.GD";
    };
    libdefaults = {
      default_realm = "SEC.GD";
      permitted_enctypes =
        "aes256-cts-hmac-sha384-192 aes128-cts-hmac-sha256-128 aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96";
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
}
