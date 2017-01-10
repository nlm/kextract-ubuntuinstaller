#!/bin/sh -eu
DEBIAN_MIRROR=${DEBIAN_MIRROR:-"http://ftp.free.fr/mirrors/ftp.debian.org"}

echo_info()
{
    echo "[+] $*"
}

usage()
{
    echo "usage: $0 ARCH DIST"
}

DEBIAN_ARCH="${1}"
DEBIAN_DIST="${2}"

case $DEBIAN_ARCH in
    amd64|arm64|i386)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${DEBIAN_ARCH}/current/images/netboot/debian-installer/${DEBIAN_ARCH}/"
        LINUX="linux"
        INITRD="initrd.gz"
        ;;
    armhf)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${DEBIAN_ARCH}/current/images/netboot/"
        LINUX="vmlinuz"
        INITRD="initrd.gz"
        ;;
    powerpc)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${DEBIAN_ARCH}/current/images/${DEBIAN_ARCH}/netboot/"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    ppc64el)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${DEBIAN_ARCH}/current/images/netboot/debian-installer/${DEBIAN_ARCH}/"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    mips|mipsel|s390x|*)
        echo "error: unsupported arch"
        usage
        exit 1
        ;;
esac

echo_info "mirror=$DEBIAN_MIRROR"
echo_info "path=$DEBIAN_SOURCE"
echo_info "arch=$DEBIAN_ARCH"
echo_info "dist=$DEBIAN_DIST"

echo_info "downloading linux image..."
wget -q $DEBIAN_SOURCE/$LINUX -O vmlinuz-${DEBIAN_DIST}-${DEBIAN_ARCH}
echo_info "downloading initrd..."
wget -q ${DEBIAN_SOURCE}/$INITRD -O initrd.gz
echo_info "extracting modules from initrd..."
gunzip < initrd.gz | cpio -id 'lib/modules/*'
echo_info "archiving modules..."
echo_info "detected kernel version: $(ls -1 lib/modules)"
tar -C lib/modules -zcf modules-${DEBIAN_DIST}-${DEBIAN_ARCH}.tar.gz .
echo_info "cleaning..."
rm -rf initrd.gz lib
echo_info "finished"
