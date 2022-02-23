{ config, pkgs, lib, ... }:
{
  time.timeZone = "US/Eastern";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = { LC_TIME = "C"; };

  boot = {
    loader.systemd-boot.enable = true;
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        authorizedKeys = config.users.users.mal.openssh.authorizedKeys.keys;
        hostKeys = [
          "/persist/etc/ssh/ssh_host_ed25519_key_initrd"
        ];
        port = 23;
      };
    };
    zfs.forceImportAll = false;
    zfs.forceImportRoot = false;
  };

  nixpkgs.config.allowUnfree = true;

  systemd.tmpfiles.rules = [
    "e /nix/var/log - - - 30d"
  ];

  zramSwap.enable = true;

  networking = {
    domain = lib.mkDefault "sec.gd";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);
    hosts = lib.mkIf
      (
        config.networking.domain == "sec.gd" &&
        config.services.tailscale.enable == true
      )
      {
        "100.64.0.1" = [ "nova.sec.gd" "nova" ];
        "100.64.0.2" = [ "xps.sec.gd" "xps" ];
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
    passwordAuthentication = false;
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
