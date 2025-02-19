#!/bin/sh

# see also https://github.com/canonical/gpu-snap/blob/929a4228ebeb17dd1cb82c48346b192ac02ac1a3/bin/gpu-2404-wrapper#L1

if snapctl is-connected gpu-2404
then
    echo "INFO: the gpu-2404 interface is connected. Running with gpu-2404 wrapper."
    #
    # We need this to help nvidia-container-toolkit with finding of
    # some configuration files so they can be bindmounted in the container
    # if needed.
    #
    export XDG_DATA_DIRS=${XDG_DATA_DIRS:+$XDG_DATA_DIRS:}/usr/share
    exec "${SNAP}/gpu-2404/bin/gpu-2404-provider-wrapper" "$@"
else
    echo "INFO: the gpu-2404 interface isn't connected. Skipping gpu-2404 wrapper."
    exec "$@"
fi