#!/bin/bash

if [ -z "$1" ]
then
    echo "Please enter slice id!"
    exit
else
    slice=$1
fi

if [ -z "$2" ]
then
    sfc=false
else
    sfc=$2
fi

if [ "$sfc" = true ]
then
    dir="overlays/sfc"
else
    dir="base"
fi

cd network-slice/$slice
# Apply Subnet
kubectl apply -f subnet/

# Apply Network-Attachment-Definition
kubectl apply -f network-attachment-definition/

# Apply UPF
kubectl apply -k upf-$slice/$dir/
kubectl -n free5gc wait --for=condition=ready pod -l app=free5gc-upf-$slice

# Apply SMF
kubectl apply -k smf-$slice/$dir/
kubectl -n free5gc wait --for=condition=ready pod -l app=free5gc-smf-$slice
