# Setup:
# mkfs.vfat -F32 /dev/nvme0n1p1
# zpool create -o ashift=12 -o autotrim=on -O compression=zstd-1 \
#   -O acltype=posixacl -O xattr=sa -O dnodesize=auto -O normalization=formD \
#   -O encryption=on -O keylocation=prompt -O keyformat=passphrase \
#   -O atime=off -O mountpoint=legacy tank /dev/nvme0n1p2
# zfs create tank/persist
# zfs create tank/home
# zfs create tank/nix
# mount -t tmpfs tmpfs /mnt
# mkdir -p /mnt/{boot,persist,home,nix}
# mount /dev/nvme0n1p1 /mnt/boot
# mount -t zfs tank/persist /mnt/persist/
# mount -t zfs tank/home /mnt/home/
# mount -t zfs tank/nix /mnt/nix/
# mkdir -p /mnt/persist/shadow /persist/etc/NetworkManager/system-connections
# nix-shell -p openssl git
# openssl passwd -6 > /mnt/persist/shadow/mal
# chmod go= /mnt/persist/shadow -R
# nixos-install --flake git+http://10.0.0.22:8080/?ref=main#xps --no-root-passwd
# zpool export tank

{ ... }:
{
  users.mutableUsers = false;
  users.users.mal.hashedPasswordFile = "/persist/shadow/mal";

  # Otherwise we're lectured again every boot
  security.sudo.extraConfig = "Defaults lecture=never";

  environment.persistence."/persist" = {
    files = [
      "/etc/krb5.keytab"
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key_initrd"
    ];
    directories = [
      "/var/log"
      "/var/lib/flatpak"
      "/var/lib/libvirt"
      "/var/lib/rasdaemon"
      "/var/lib/tailscale"
    ];
  };
  environment.etc."NetworkManager/system-connections".source =
    "/persist/etc/NetworkManager/system-connections";

  fileSystems = {
    "/" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "mode=755" ]; };
    "/boot" = { device = "/dev/disk/by-partlabel/_esp"; };
    "/nix" = { device = "tank/nix"; fsType = "zfs"; };
    "/persist" = { device = "tank/persist"; fsType = "zfs"; neededForBoot = true; };
  };
}
