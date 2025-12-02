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
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.mal.impermanence;
in {
  options.mal.impermanence.enable = lib.mkOption {
    default = true;
    description = "Use intransience for tmpfs root filesystem";
    type = lib.types.bool;
  };

  imports = [
    inputs.intransience.nixosModules.default
  ];

  config = mkIf cfg.enable {
    intransience = {
      enable = true;
      datastores = {
        persist = {
          enable = true;
          path = "/persist";
          etc = {
            files = [
              "machine-id"
            ];
            dirs = [
              (mkIf config.networking.networkmanager.enable {
                path = "NetworkManager/system-connections";
                mode = "0700";
              })
            ];
          };
          dirs = [
            "/var/log"
          ];
          byPath = {
            "/var/lib" = {
              dirs = [
                "nixos"
                "systemd/backlight"
                "systemd/pstore"
                "systemd/rfkill"
                "systemd/timers"
                (mkIf (config.security.acme.certs != {}) "acme")
                # https://stackoverflow.com/questions/65957677/
                (mkIf config.hardware.bluetooth.enable "bluetooth")
                (mkIf config.services.flatpak.enable "flatpak")
                (mkIf config.virtualisation.libvirtd.enable "libvirt")
                (mkIf config.hardware.rasdaemon.enable "rasdaemon")
                (mkIf config.virtualisation.libvirtd.qemu.swtpm.enable "swtpm-localca")
                (mkIf config.services.tailscale.enable "tailscale")
                {
                  # bound instead of configured with pkiBundle so that `sbctl` works
                  path = "sbctl";
                  mode = "0700";
                }
              ];
              files = [
                (mkIf config.networking.networkmanager.enable {
                  path = "NetworkManager/secret_key";
                  method = "symlink";
                  mode = "0600";
                })
                {
                  path = "systemd/random-seed";
                  method = "symlink";
                  mode = "0600";
                }
              ];
            };
          };
        };
        persist-nobackup-cache = {
          enable = true;
          path = "/persist/nobackup/cache";
          dirs = [
            (mkIf config.services.fwupd.enable "/var/cache/fwupd")
            (mkIf config.services.displayManager.sddm.enable {
              path = "/var/lib/sddm/.cache";
              parentDirectory = {
                user = "sddm";
                group = "sddm";
                mode = "0750";
              };
            })
          ];
        };
      };
    };

    # DynamicUser=true so StateDir must be in /var/lib. Having mounts there
    # before namespace setup breaks that. So just have preStart symlink it in.
    systemd.services = lib.genAttrs ["authentik" "authentik-worker"] (_: {
      preStart = ''ln -svfn /persist/authentik/media /var/lib/authentik/media'';
    });

    services = {
      jellyfin = {
        cacheDir = "/persist/nobackup/cache/jellyfin";
        dataDir = "/persist/jellyfin";
      };
      mosquitto.dataDir = "/persist/mosquitto";
      ollama.models = "/persist/nobackup/ollama-models";
      postgresql.dataDir = "/persist/postgresql/${config.services.postgresql.package.psqlSchema}";
    };

    users.mutableUsers = false;
    users.users.mal.hashedPasswordFile = "/persist/shadow/mal";

    # Otherwise we're lectured again every boot
    security.sudo.extraConfig = "Defaults lecture=never";

    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = ["mode=755" "size=25%" "huge=within_size"];
      };
      "/boot" = {
        device = "/dev/disk/by-partlabel/esp";
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
