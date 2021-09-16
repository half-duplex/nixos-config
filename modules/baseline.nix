{ config, pkgs, ...}:
{
    time.timeZone = "US/Eastern";
    i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    i18n.extraLocaleSettings = { LC_TIME = "C"; };

    boot = {
        loader.systemd-boot.enable = true;
        initrd.network = {
            enable= true;
            ssh = {
                enable = true;
                authorizedKeys = [
                    "fake"
                ];
                hostKeys = [
                    "/etc/ssh/ssh_host_ed25519_key_initrd"
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

    networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);
    networking.wireguard.enable = true;

    nix.package = pkgs.nixFlakes;

    hardware.cpu = {
        amd.updateMicrocode = true;
        intel.updateMicrocode = true;
    };

    users.users.mal = {
        isNormalUser = true;
        extraGroups = [ "wheel" "audio" "video" "networkmanager" "dialout" "input" "wireshark" ];
    };

    virtualisation.docker = { enable = true; enableOnBoot = false; };

    services.openssh = {
        enable = true;
        passwordAuthentication = false;
    };

    krb5 = {
        enable = true;
        domain_realm = {
            "sec.gd" = "SEC.GD";
            ".sec.gd" = "SEC.GD";
        };
        libdefaults = {
            default_realm = "SEC.GD";
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

    environment.systemPackages = with pkgs; [
        qemu_kvm
        libvirt
    ];
}
