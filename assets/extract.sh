#!/bin/sh -eu

echo_info()
{
    echo "[+] $*"
}

usage()
{
    echo "usage: $0 ARCH DIST"
}

UBUNTU_ARCH="${1}"
UBUNTU_DIST="${2}"

case $UBUNTU_ARCH in
    i386|amd64)
        UBUNTU_SOURCE="http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/netboot/ubuntu-installer/${UBUNTU_ARCH}"
        LINUX="linux"
        INITRD="initrd.gz"
        ;;
    arm64)
        UBUNTU_SOURCE="http://ports.ubuntu.com/ubuntu-ports/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/netboot/ubuntu-installer/${UBUNTU_ARCH}"
        LINUX="linux"
        INITRD="initrd.gz"
        ;;
    armhf)
        UBUNTU_SOURCE="http://ports.ubuntu.com/ubuntu-ports/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/generic/netboot/"
        LINUX="vmlinuz"
        INITRD="initrd.gz"
        ;;
    powerpc)
        UBUNTU_SOURCE="http://ports.ubuntu.com/ubuntu-ports/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/${UBUNTU_ARCH}/netboot"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    powerpc64)
        UBUNTU_SOURCE="http://ports.ubuntu.com/ubuntu-ports/dists/${UBUNTU_DIST}/main/installer-powerpc/current/images/${UBUNTU_ARCH}/netboot"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    ppc64el)
        UBUNTU_SOURCE="http://ports.ubuntu.com/ubuntu-ports/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/netboot/ubuntu-installer/${UBUNTU_ARCH}"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    *)
        echo "error: unsupported arch"
        usage
        exit 1
        ;;
esac

echo_info "source=$UBUNTU_SOURCE"
echo_info "arch=$UBUNTU_ARCH"
echo_info "dist=$UBUNTU_DIST"

echo_info "downloading linux image..."
wget -q "${UBUNTU_SOURCE}/$LINUX" -O "vmlinuz-${UBUNTU_DIST}-${UBUNTU_ARCH}"
echo_info "downloading initrd..."
wget -q "${UBUNTU_SOURCE}/$INITRD" -O "initrd.gz"
echo_info "extracting modules from initrd..."
gunzip < "initrd.gz" | cpio -id 'lib/modules/*'
echo_info "archiving modules..."
echo_info "detected kernel version: $(ls -1 lib/modules)"
tar -C "lib/modules" -zcf "modules-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar.gz" .
echo_info "cleaning..."
rm -rf "initrd.gz" "lib"
echo_info "finished"
