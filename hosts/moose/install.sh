#!/usr/bin/env bash

set -euo pipefail

osdisk="${osdisk:-/dev/mmcblk1}"
mountpath="${mountpath:-/mnt}"
hostname="${hostname:-moose}"
flake="git+https://github.com/half-duplex/nixos-config.git?ref=main"

wipe=""
format=""
install=""
mount=""
dryrun=""
swap=""
pi=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --wipe)
            wipe="wipe"
        ;;
        --format) # requires wipe
            format="format"
        ;;
        --install) # requires wipe+format
            install="install"
        ;;
        --leave-mounted) # don't clean up mounts after
            mount="keep"
        ;;
        --dry-run)
            dryrun="dryrun"
        ;;
        --swap) # =0 to disable
            swap="$2"
            shift
        ;;
        --pi)
            pi="yes"
        ;;
        --disk)
            osdisk="$2"
            shift
        ;;
        --mount-path)
            mountpath="$2"
            shift
        ;;
        --hostname)
            hostname="$2"
            shift
        ;;
        -h|--help)
            cat <<EOF
Flags:
    --wipe, --format, --install
        Each requires all of the previous. Cross-arch installs don't seem to work
    --leave-mounted
        Don't unmount the new filesystems after attempting the requested actions
    --dry-run
        Print the commands that *would* be run
    --swap <amount>
        How much swap? 0 or "" for none. Uses sgdisk syntax, e.g. "8GiB"
    --pi
        Add a partition for /boot/firmware
    --disk <path>
        Path of the block device to wipe and set up
    --mount-path <path>
        Where to mount the filesystems for installation. Default "/mnt"
    --hostname <hostname>
        For the zfs partition name and nixos-install
EOF
            exit 0
            ;;
        *)
            echo "Unknown argument $1"
            exit 1
        ;;
    esac
    shift
done

[ "$hostname" == "moose" ] && pi="4"

osdisk="$(realpath "$osdisk")" # follow symlinks like /dev/disk/by-id/...
echo "$osdisk" | grep -qE '/(loop|mmcblk|nvme[0-9]+n)[0-9]+$' && partp="p" || partp=""
mountpath="$(realpath "$mountpath")" # strip trailing slash

wipe() {
    echo "Zeroing first and last 1MiB of $1"
    drywrap dd status=none if=/dev/zero of="$1" bs=1M count=1
    drywrap dd status=none if=/dev/zero of="$1" bs=1M count=1 \
        seek=$(($(blockdev --getsize64 "$1")/1024/1024-1))
}

zpool_exists() {
    zpool status "$1" &>/dev/null || return 1
}

mounts_under() {
    awk '{print $2}' /proc/mounts | grep -E '^'"$1"'($|/)' || true
}

cleanup() {
    echo -e "\nCleaning up"
    if [ "$mount" != "keep" ] ; then
        mounts_under "$mountpath" | sort -r | while read -r mount ; do
            drywrap umount "$mount"
        done
        [ -n "${poolname:-}" ] && zpool_exists "$poolname" \
            && drywrap zpool export "$poolname"
    else
        echo -n "Don't forget to unmount everything under $mountpath and "
        echo "\`zpool export $poolname\`"
    fi
}

if [ "$UID" != "0" ] ; then
    echo "This script must be run as root"
    exit 1
fi
for dependency in zpool sgdisk partprobe tr dd jq mkfs.vfat ; do
    if ! which $dependency &>/dev/null ; then
        echo "Couldn't find dependency $dependency"
        exit 1
    fi
done
if [ ! -b "$osdisk" ] ; then
    echo "$osdisk doesn't seem like a block device"
    exit 1
fi
if awk '{print $1}' /proc/mounts | grep -qE "^${osdisk}(${partp}[0-9])?" ; then
    echo "A filesystem on $osdisk is mounted, exiting in case you chose the wrong disk to wipe"
    exit 1
fi
if zpool status -LPj --json-flat-vdevs \
    | jq -r '.pools[].vdevs[]|select(.vdevs).vdevs[].name' \
    | grep -qE "^${osdisk}(${partp}[0-9])?"
then
    echo "A zfs pool on $osdisk is imported, exiting in case you chose the wrong disk to wipe"
    exit 1
fi
if [ -n "$(ls "$mountpath" 2>/dev/null)" ] ; then
    echo "The mount directory $mountpath should be empty"
    exit 1
fi
if [ -n "$(mounts_under "$mountpath")" ] ; then
    echo "There's already something mounted at/under $mountpath"
    exit 1
fi
if [ -z "$wipe" ] ; then
    echo "What do you want me to do? See --help"
    exit 1
fi

trap cleanup EXIT

if [ -z "$dryrun" ] ; then
    echo -e "\nWEAPONS LIVE: About to destroy all data on ${osdisk}\n"
    lsblk "$osdisk"
    sleep 3
    drywrap() { "$@" ; }
else
    drywrap() { echo "Would run:" "$@" ; }
fi

if [ "$wipe" == "wipe" ] ; then
    # wipe all partitions then partition table
    devices="$(ls "${osdisk}${partp}"[0-9]* 2>/dev/null || true)"
    for device in $devices ; do
        wipe "$device"
    done
    wipe "$osdisk"
fi

if [ "$format" == "format" ] ; then
    if [ "$wipe" != "wipe" ] ; then
        echo "You must specify --wipe to use --format"
        exit 1
    fi

    # partition
    partno_boot=1 partno_pool=2 partno_swap=3
    [ -n "$pi" ] && partno_boot=2 partno_pool=3 partno_swap=4
    [ -n "$pi" ] && drywrap sgdisk \
        -n 1::+128MiB -t 1:0700 -c 1:firmware -A 1:set:0 \
        "$osdisk"
    drywrap sgdisk \
        -n $partno_boot::+1GiB -t $partno_boot:EF00 -c $partno_boot:esp \
        "$osdisk"
    [ -n "$swap" ] && [ "$swap" != "0" ] && drywrap sgdisk \
        -n $partno_swap:-"$swap": -t $partno_swap:8200 -c $partno_swap:swap \
        "$osdisk"
    drywrap sgdisk \
        -n $partno_pool:: -t $partno_pool:8300 -c $partno_pool:"$hostname" \
        "$osdisk"
    partprobe

    # format
    drywrap mkfs.vfat -F32 "${osdisk}${partp}1"
    [ -n "$pi" ] && drywrap mkfs.vfat -F32 "${osdisk}${partp}2"

    poolname="tank-inst-$(tr -cd '[:alnum:]' </dev/urandom | dd bs=10 count=1 status=none || true)"
    echo "Creating zpool with temporary name $poolname"
    drywrap zpool create \
        -o ashift=12 \
        -o autotrim=on \
        -O acltype=posixacl \
        -O atime=off \
        -O canmount=off \
        -O compression=zstd-1 \
        -O dnodesize=auto \
        -O encryption=on \
        -O keylocation=prompt \
        -O keyformat=passphrase \
        -O mountpoint=none \
        -O normalization=formD \
        -O xattr=sa \
        tank -t "${poolname}" "${osdisk}${partp}${partno_pool}"
    echo "To import despite a duplicate pool name, use the pool GUID:"
    pool_guid="3x4mpl3"
    [ -z "$dryrun" ] && \
        pool_guid="$(zpool status -j "$poolname" | jq -r '.pools[].pool_guid')"
    echo "# zpool import $pool_guid -t temp-pool-name"

    for dataset in nix {home,persist}{,/nobackup} ; do
        drywrap zfs create -o mountpoint=legacy "${poolname}/${dataset}"
    done
fi

if [ "$install" == "install" ] ; then
    if [ "$wipe" != "wipe" ] || [ "$format" != "format" ] ; then
        echo "You must specify --wipe and --format to use --install"
        exit 1
    fi

    # mount
    drywrap mount -m -t tmpfs tmpfs "${mountpath}"
    drywrap mount -m "${osdisk}${partp}${partno_boot}" "${mountpath}/boot"
    [ -n "$pi" ] && drywrap mount -m "${osdisk}${partp}1" "${mountpath}/boot/firmware"
    for dataset in nix {home,persist}{,/nobackup} ; do
        drywrap mount -m -t zfs "${poolname}/${dataset}" "${mountpath}/${dataset}"
    done

    # prepare and install
    drywrap mkdir -p "${mountpath}/persist/"{shadow,secureboot,ssh,NetworkManager/system-connections}
    drywrap ssh-keygen -t ed25519 -N '' -C '' -f "${mountpath}/persist/ssh/ssh_host_ed25519_key_initrd"
    hash="$(mkpasswd -m yescrypt)"
    drywrap install -Dm 600 <(echo "$hash") "${mountpath}/persist/shadow/mal"
    drywrap nix-shell -p git --command "
        nixos-install --no-channel-copy --no-root-password \
            --root '$mountpath' --flake '$flake'#'$hostname'
    "
fi
