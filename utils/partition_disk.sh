#!/bin/bash
if [[ $# -ne 2 ]]; then
    echo "Requires a disk name and mounted path name"
    echo "$(basename $0) disk path"
    exit 1
fi
set -e
parted ${1} --script mklabel gpt
parted ${1} --script mkpart primary '0%' '100%'
mkfs.xfs -f -n ftype=1 ${1}1
mkdir -p ${2}
echo "${1}1       ${2}              xfs     defaults,noatime    1 2" >> /etc/fstab
mount ${2}


echo "forwarding"
sysctl -w net.ipv4.ip_forward=1

exit 0
