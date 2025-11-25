#!/usr/bin/env bash
set -euo pipefail

VCP_BRIGHTNESS="0x10" # MCCS defines 0x10 as Luminance

brightness=${1:-}
displays=${2:-}
displays=${displays//,/ }
if [ "$brightness" != "${brightness##*[!0-9]*}" ] \
    || [ "$displays" != "${displays##*[!0-9 ]*}" ]
then
    echo "Usage: $0 [brightness [display[,display...]]]"
    echo "  brightness: 0-100"
    echo "  display: display number as known by ddcutil"
    echo "Without arguments, shows current display brightness"
    exit 1
fi

# Ensure root, using pkexec for gui support
[ "$UID" -eq 0 ] || exec pkexec "$0" "$@"

if [ -z "$displays" ] ; then
    # Get DDC display IDs
    displays=$(ddcutil detect -t | grep '^Display ' | cut -d' ' -f2 | xargs echo)
fi

if [ "$#" -eq 0 ] || [ -z "$brightness" ] ; then
    # Show current brightness
    for display in $displays ; do
        echo -n "Display $display: "
        ddcutil -d "$display" -t getvcp "$VCP_BRIGHTNESS" \
            | cut -d' ' -f4
    done
    exit 0
fi

# Set brightness
for display in $displays ; do
    ddcutil -d "$display" setvcp "$VCP_BRIGHTNESS" "$brightness"
done
