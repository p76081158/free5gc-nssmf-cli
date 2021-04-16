#!/bin/bash

if [ -z "$1" ]
then
    sfc=false
else
    sfc=$1
fi

if [ "$sfc" = true ]
then
    dir="overlays/sfc"
else
    dir="base"
fi

# Apply subnet
kubectl apply -f subnet/

# Apply UPF
kubectl apply -k upf-0x01010203/$dir/
kubectl wait --for=condition=ready pod -l app=free5gc-upf-0x01010203

# Apply SMF
kubectl apply -k smf-0x01010203/$dir/
kubectl wait --for=condition=ready pod -l app=free5gc-smf-0x01010203
