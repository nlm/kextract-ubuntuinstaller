#!/bin/sh -eu
DEBIAN_MIRROR=${DEBIAN_MIRROR:-"http://ftp.free.fr/mirrors/ftp.debian.org"}
DEBIAN_DIST=${DEBIAN_DIST:-jessie}

echo_info()
{
    echo "[+] $*"
}

usage()
{
    echo "usage: $0 ARCH"
}

ARCH="$1"

case $ARCH in
    amd64|arm64|i386)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${ARCH}/current/images/netboot/debian-installer/${ARCH}/"
        LINUX="linux"
        INITRD="initrd.gz"
        ;;
    armhf)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${ARCH}/current/images/netboot/"
        LINUX="vmlinuz"
        INITRD="initrd.gz"
        ;;
    powerpc)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${ARCH}/current/images/${ARCH}/netboot/"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    ppc64el)
        DEBIAN_SOURCE="${DEBIAN_MIRROR}/dists/${DEBIAN_DIST}/main/installer-${ARCH}/current/images/netboot/debian-installer/${ARCH}/"
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
echo_info "arch=$ARCH"

echo_info "downloading linux image..."
wget -q $DEBIAN_SOURCE/$LINUX -O vmlinuz-${ARCH}
echo_info "downloading initrd..."
wget -q ${DEBIAN_SOURCE}/$INITRD -O initrd.gz
echo_info "extracting modules from initrd..."
gunzip < initrd.gz | cpio -id 'lib/modules/*'
echo_info "archiving modules..."
tar -C lib/modules -zcf modules-${ARCH}.tar.gz .
echo_info "cleaning..."
rm -rf initrd.gz lib
echo_info "finished"
