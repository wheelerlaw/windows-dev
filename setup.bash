#!/usr/bin/env bash
set -xe
/bin/rsync -a ./rootfs/ /

echo "Installing root certs"
/bin/update-ca-trust

echo "Installing packages"

apt-cyg install git nano vim dos2unix socat

echo "Done!"
