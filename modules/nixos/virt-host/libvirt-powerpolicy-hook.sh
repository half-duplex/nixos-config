#!/usr/bin/env bash

set -eux

if [ "$#" -lt 2 ] || [ "$1" != "-" ] ; then
    # not run in the expected way (- shutdown - shutdown)
    exit
fi
event="$2"

policy_uri="http://sec.gd/xmlns/libvirt/hostpowerpolicy"
policy_key="hostpowerpolicy"

virsh list --state-running --uuid --name | grep . \
    | while read -r vm
do
    uuid=${vm% *}
    name=${vm##* }

    # crimes, but how else?
    action="$(
        virsh metadata --domain "$uuid" --uri "$policy_uri" --key "$policy_key" \
            | grep '<event ' \
            | grep " name=\"$event\"" \
            | sed -re 's/.* action="([^"]+)".*/\1/'
    )"

    case "$action" in
        shutdown)
            echo "Shutting down $name..." >&2
            virsh shutdown --domain "$uuid"
            ;;
        *)
            echo "Unknown action $action for VM %name" >&2
            ;;
    esac
    # may need to block?
done
