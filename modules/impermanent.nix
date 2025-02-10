# Setup:
# nix-shell -p openssl git
# parted /dev/nvme0n1 mklabel gpt
# parted /dev/nvme0n1 mkpart _esp fat32 0% 1G
# parted /dev/nvme0n1 set 1 esp on
# parted /dev/nvme0n1 mkpart _tank 1G 100%
# mkfs.vfat -F32 /dev/nvme0n1p1
# zpool create -o ashift=12 -o autotrim=on -O compression=zstd-1 \
#   -O acltype=posixacl -O xattr=sa -O dnodesize=auto -O normalization=formD \
#   -O encryption=on -O keylocation=prompt -O keyformat=passphrase \
#   -O atime=off -O mountpoint=legacy tank /dev/nvme0n1p2
# zfs create tank/persist
# zfs create tank/home
# zfs create tank/nix
# mount -t tmpfs tmpfs /mnt
# cd /mnt
# mkdir -p {boot,persist,home,nix}
# mount /dev/nvme0n1p1 boot
# for ds in persist home nix ; do mount -t zfs tank/$ds $ds ; done
# mkdir -p persist/{shadow,secureboot,ssh,NetworkManager/system-connections}
# ssh-keygen -t ed25519 -N '' -C '' -f ssh/ssh_host_ed25519_key_initrd
# openssl passwd -6 > /mnt/persist/shadow/mal
# chmod go= /mnt/persist/shadow -R
# nixos-install --no-root-password \
#   --flake git+https://github.com/half-duplex/nixos-config.git?ref=main#hostname
# zpool export tank
# Once booted: https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
# sbctl create-keys
# Enable SB in host config.nix, rebuild, setup mode in fw
# sudo sbctl enroll-keys --microsoft
{config, ...}: {
  users.mutableUsers = false;
  users.users.mal.hashedPasswordFile = "/persist/shadow/mal";

  # Otherwise we're lectured again every boot
  security.sudo.extraConfig = "Defaults lecture=never";

  services = {
    jellyfin = {
      cacheDir = "/persist/nobackup/jellyfin/cache";
      dataDir = "/persist/jellyfin";
    };
    ollama.models = "/persist/nobackup/ollama-models";
    openssh.hostKeys = [
      {
        path = "/persist/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/persist/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
    postgresql.dataDir = "/persist/postgresql/${config.services.postgresql.package.psqlSchema}";
  };

  environment.persistence."/persist" = {
    files = [
      "/etc/krb5.keytab"
      "/etc/machine-id"
    ];
    directories = [
      "/var/log"
      "/var/lib/acme"
      "/var/lib/flatpak"
      "/var/lib/libvirt"
      "/var/lib/nixos"
      "/var/lib/rasdaemon"
      "/var/lib/tailscale"
      "/var/lib/swtpm-localca"
    ];
  };
  environment.etc.secureboot.source = "/persist/secureboot";
  environment.etc."NetworkManager/system-connections".source = "/persist/NetworkManager/system-connections";

  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["mode=755"];
    };
    "/boot" = {device = "/dev/disk/by-partlabel/_esp";};
    "/home" = {
      device = "tank/home";
      fsType = "zfs";
    };
    "/home/nobackup" = {
      device = "tank/home/nobackup";
      fsType = "zfs";
    };
    "/nix" = {
      device = "tank/nix";
      fsType = "zfs";
    };
    "/persist" = {
      device = "tank/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persist/nobackup" = {
      device = "tank/persist/nobackup";
      fsType = "zfs";
    };
  };
}
