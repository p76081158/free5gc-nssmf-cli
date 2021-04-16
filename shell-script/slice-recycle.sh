#!/bin/bash

if [ -z "$1" ]
then
    echo "Please enter slice id!"
    exit
else
    slice=$1
fi

cd network-slice
rm -rf $slice
