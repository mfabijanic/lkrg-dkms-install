#!/bin/bash
# LKRG (Linux Kernel Runtime Guard) - DKMS installation script
#
# Description:
# LKRG performs runtime integrity checking of the Linux kernel and
# detection of security vulnerability exploits against the kernel.
#
# Author: Matej Fabijanic <root4unix@gmail.com>

# LKRG version
version="0.9.1"

work="$(cd $(dirname $0) && pwd)"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
export PATH
pkgs="wget dkms"

if [ ! -f "/etc/os-release" ]; then
    echo "File /etc/os-release does not exist. Unsupported."
    exit 1
fi

source /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "Ubuntu is only supported operating system at this time."
    exit 1
fi

# ID: ubuntu, debian, kali...
# ID_LIKE: debian, "rhel fedora"
dkms_template="$work/dkms-${ID}.conf.template"

for pkg in ${pkgs}; do
    if ! (which ${pkg} &>/dev/null); then
        echo "${pkg} is not installed. Install it first."
	source /etc/os-release
	if [ "$ID_LIKE" = "debian" ]; then
	    echo "  sudo -y apt-get install ${pkg}"
	fi
        exit 1
    fi
done

# Import openwall-offline-signatures.asc
curl https://www.openwall.com/signatures/openwall-offline-signatures.asc | gpg --import -

cd /usr/local/src
wget -c https://www.openwall.com/lkrg/lkrg-${version}.tar.gz
wget -c https://www.openwall.com/lkrg/lkrg-${version}.tar.gz.sign
gpg --verify lkrg-${version}.tar.gz.sign lkrg-${version}.tar.gz
if [ $? -ne 0 ]; then
    echo "Package Signature isn't OK. Abort installation."
    exit 1
fi

if [ ! -d /usr/src/lkrg-${version} ]; then
    echo "Extract package in /usr/src"
    cd /usr/src
    tar xzf /usr/local/src/lkrg-${version}.tar.gz
fi

echo "Create /usr/src/lkrg-${version}/dkms.conf"
cat ${dkms_template} | sed s/__VERSION__/${version}/g >/usr/src/lkrg-${version}/dkms.conf

dkms install lkrg/${version}
dkms_install_status=$?

if [ $dkms_install_status -ne 0 ]; then
    echo "DKMS: LKRG install FAILED"
    exit $dkms_install_status
fi

echo
echo "Start lkrg.service"
systemctl start lkrg

echo
echo "Uninstall DKMS LKRG with:"
echo "  sudo dkms uninstall -m lkrg/${version}"
echo "Remove DKMS LKRG with:"
echo "  sudo dkms remove -m lkrg/${version} --all"
echo
echo "DKMS status"
dkms status

