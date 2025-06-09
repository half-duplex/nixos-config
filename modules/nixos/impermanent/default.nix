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
{
  config,
  lib,
  namespace,
  ...
}: {
  options.${namespace}.impermanence.enable = lib.mkOption {
    default = true;
    description = "Use intransience for tmpfs root filesystem";
    type = lib.types.bool;
  };

  config = lib.mkIf config.${namespace}.impermanence.enable {
    intransience = {
      enable = true;
      datastores = {
        "/persist" = {
          enable = true;
          etc = {
            files = [
              "machine-id"
            ];
            dirs = [
              "NetworkManager/system-connections"
              "secureboot"
            ];
          };
          dirs = [
            "/var/log"
          ];
          byPath = {
            "/var/lib" = {
              dirs = [
                "acme"
                "bluetooth" # https://stackoverflow.com/questions/65957677/
                "flatpak"
                "libvirt"
                "nixos"
                "rasdaemon"
                "swtpm-localca"
                "systemd/backlight"
                "systemd/pstore"
                "systemd/rfkill"
                "systemd/timers"
                "tailscale"
              ];
              files = [
                "NetworkManager/secret_key"
                "systemd/random-seed"
              ];
            };
            "/var/lib/private".dirs = [
              # Because the services use DynamicUser the media dir must be in /var/lib
              (lib.mkIf config.${namespace}.services.authentik.enable "authentik/media")
            ];
          };
        };
        "/persist/nobackup/cache" = {
          enable = true;
          dirs = [
            "/var/cache/fwupd"
            "/var/lib/sddm/.cache"
          ];
        };
      };
    };

    users.mutableUsers = false;
    users.users.mal.hashedPasswordFile = "/persist/shadow/mal";

    # Otherwise we're lectured again every boot
    security.sudo.extraConfig = "Defaults lecture=never";

    services = {
      jellyfin = {
        cacheDir = "/persist/nobackup/cache/jellyfin";
        dataDir = "/persist/jellyfin";
      };
      ollama.models = "/persist/nobackup/ollama-models";
      postgresql.dataDir = "/persist/postgresql/${config.services.postgresql.package.psqlSchema}";
    };

    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = ["mode=755" "size=25%" "huge=within_size"];
      };
      "/boot" = {
        device = "/dev/disk/by-partlabel/_esp";
        options = ["umask=0077"]; # protect /boot/loader/random-seed
      };
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
  };
}
