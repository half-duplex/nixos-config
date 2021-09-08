# Setup:
# mkfs.vfat -F32 /dev/nvme0n1p1
# cryptsetup luksFormat --sector-size 4096 /dev/nvme0n1p2
# cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent open /dev/nvme0n1p2 cryptroot
# zpool create -o ashift=12 -o autotrim=on -O compression=zstd-1 -O acltype=posixacl -O xattr=sa -O atime=off -O mountpoint=legacy tank /dev/mapper/cryptroot
# zfs create tank/persist
# zfs create tank/nix
# mount -t tmpfs tmpfs /mnt
# mkdir -p /mnt/{boot,nix,persist}
# mount /dev/nvme0n1p1 /mnt/boot
# mount -t zfs tank/persist /mnt/persist/
# mount -t zfs tank/nix /mnt/nix/
# nix-shell -p nixFlakes
# mkdir -p /mnt/persist/shadow
# openssl passwd -6 > /mnt/persist/shadow/mal
# chmod go= /mnt/persist/shadow -R
# nixos-install --flake git+http://10.0.0.22:8080/?ref=main#xps --no-root-passwd
# zpool export tank

{ pkgs, ... }:
{
    users.mutableUsers = false;
    users.users.mal.passwordFile = "/persist/shadow/mal";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices.cryptroot = { device = "/dev/disk/by-partlabel/_luks"; };

    environment.persistence."/persist" = {
        files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key_initrd"
        ];
        directories = [
            "/home"
            "/var/log"
        ];
    };

    fileSystems = {
        "/" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "mode=755" ]; };
        "/boot" = { device = "/dev/disk/by-partlabel/_esp"; };
        "/nix" = { device = "tank/nix"; fsType = "zfs"; };
        "/persist" = { device = "tank/persist"; fsType = "zfs"; neededForBoot = true; };
    };
}
