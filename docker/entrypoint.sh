#!/bin/bash -e
echo "Running Blin with parameters: $@"
cp -r /Blin/* /mnt
cd /mnt
bin/blin.p6 $@
