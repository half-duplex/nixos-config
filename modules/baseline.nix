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
                authorizedKeys = config.users.users.mal.openssh.authorizedKeys.keys;
                hostKeys = [
                    "/etc/ssh/ssh_host_ed25519_key_initrd"
                ];
                port = 23;
            };
        };
        initrd.secrets = {
            "/etc/ssh/ssh_host_ed25519_key_initrd" =
                "/etc/ssh/ssh_host_ed25519_key_initrd";
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

    users.groups.ssh-users = {};
    users.users.root.extraGroups = [ "ssh-users" ];
    users.users.mal = {
        isNormalUser = true;
        extraGroups = [ "wheel" "ssh-users" "audio" "video" "networkmanager" "dialout" "input" "wireshark" "libvirtd" ];
    };

    virtualisation.docker = { enable = true; enableOnBoot = false; };
    virtualisation.libvirtd.qemuRunAsRoot = false;

    services.openssh = {
        enable = true;
        passwordAuthentication = false;
        extraConfig = ''
            AllowGroups ssh-users
            GSSAPIAuthentication yes
        '';
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
}
