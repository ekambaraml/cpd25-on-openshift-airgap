#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Requires a disk name and mounted path name"
    echo "$(basename $0) <disk> <path>"
    exit 1
fi
set -e
wipefs -a -f  ${1}
exit 0
