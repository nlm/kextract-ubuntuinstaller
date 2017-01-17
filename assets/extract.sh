#!/bin/sh -eu

echo_info()
{
    echo "[+] $*"
}

echo_subinfo()
{
    echo "    $*"
}

usage()
{
    echo "usage: $0 ARCH DIST"
}

UBUNTU_ARCH="${1}"
UBUNTU_DIST="${2}"

case $UBUNTU_ARCH in
    i386|amd64)
        UBUNTU_REPO="http://archive.ubuntu.com/ubuntu"
        UBUNTU_INSTALLER="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/netboot/ubuntu-installer/${UBUNTU_ARCH}"
        UBUNTU_PKGIDX="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/debian-installer/binary-${UBUNTU_ARCH}/Packages.gz"
        LINUX="linux"
        INITRD="initrd.gz"
        ;;
    arm64)
        UBUNTU_REPO="http://ports.ubuntu.com/ubuntu-ports"
        UBUNTU_INSTALLER="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/netboot/ubuntu-installer/${UBUNTU_ARCH}"
        UBUNTU_PKGIDX="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/debian-installer/binary-${UBUNTU_ARCH}/Packages.gz"
        LINUX="linux"
        INITRD="initrd.gz"
        ;;
    armhf)
        UBUNTU_REPO="http://ports.ubuntu.com/ubuntu-ports"
        UBUNTU_INSTALLER="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/generic/netboot/"
        UBUNTU_PKGIDX="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/debian-installer/binary-${UBUNTU_ARCH}/Packages.gz"
        LINUX="vmlinuz"
        INITRD="initrd.gz"
        ;;
    powerpc)
        UBUNTU_REPO="http://ports.ubuntu.com/ubuntu-ports"
        UBUNTU_INSTALLER="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/${UBUNTU_ARCH}/netboot"
        UBUNTU_PKGIDX="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/debian-installer/binary-${UBUNTU_ARCH}/Packages.gz"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    powerpc64)
        UBUNTU_REPO="http://ports.ubuntu.com/ubuntu-ports"
        UBUNTU_INSTALLER="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/installer-powerpc/current/images/${UBUNTU_ARCH}/netboot"
        UBUNTU_PKGIDX="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/debian-installer/binary-${UBUNTU_ARCH}/Packages.gz"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    ppc64el)
        UBUNTU_REPO="http://ports.ubuntu.com/ubuntu-ports"
        UBUNTU_INSTALLER="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/installer-${UBUNTU_ARCH}/current/images/netboot/ubuntu-installer/${UBUNTU_ARCH}"
        UBUNTU_PKGIDX="${UBUNTU_REPO}/dists/${UBUNTU_DIST}/main/debian-installer/binary-${UBUNTU_ARCH}/Packages.gz"
        LINUX="vmlinux"
        INITRD="initrd.gz"
        ;;
    *)
        echo "error: unsupported arch"
        usage
        exit 1
        ;;
esac

echo_info "repo=$UBUNTU_REPO"
echo_info "installer=$UBUNTU_INSTALLER"
echo_info "pkgidx=$UBUNTU_PKGIDX"
echo_info "arch=$UBUNTU_ARCH"
echo_info "dist=$UBUNTU_DIST"

echo_info "downloading linux image..."
wget -q "${UBUNTU_INSTALLER}/$LINUX" -O "vmlinuz-${UBUNTU_DIST}-${UBUNTU_ARCH}"
echo_info "downloading initrd..."
wget -q "${UBUNTU_INSTALLER}/$INITRD" -O "initrd.gz"
echo_info "extracting modules from initrd..."
gunzip < "initrd.gz" | cpio -id 'lib/modules/*'
echo_info "archiving modules..."
kernel_version=$(ls -1 lib/modules | head -n 1)
echo_info "detected kernel version: ${kernel_version}"
tar -C "lib/modules" -zcf "modules-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar.gz" .
echo_info "cleaning..."
rm -rf "initrd.gz" "lib"

echo_info "creating temp dirs..."
TMP_PKG_INDEX="/tmp/pkg.index"
TMP_PKG_DIR="/tmp/pkg"
TMP_MOD_DIR="/tmp/mod"
mkdir -p "${TMP_PKG_DIR}" "${TMP_MOD_DIR}"
echo_info "downloading installer package index..."
wget -q -O - "${UBUNTU_PKGIDX}" \
    | gunzip | grep '^\(Package:\|Filename:\)' | cut -d':' -f 2 | xargs -n 2 echo > "${TMP_PKG_INDEX}"
echo_info "downloading extra packages..."
for path in $(cat "${TMP_PKG_INDEX}" | grep '^[a-z][a-z]*-modules-'"${kernel_version}"'-di ' | cut -d' ' -f2); do
    pkg_url="${UBUNTU_REPO}/${path}"
    pkg_file="${TMP_PKG_DIR}/$(basename ${path})"
    echo_subinfo "downloading ${pkg_url}..."
    wget -q "${pkg_url}" -O "${pkg_file}"
    echo_subinfo "extracting ${pkg_file}..."
    dpkg --extract "${pkg_file}" "${TMP_MOD_DIR}"
done
if [ -e "${TMP_MOD_DIR}/lib/modules" ]; then
    echo_info "detected extra modules kernel version: $(ls ${TMP_MOD_DIR}/lib/modules)"
    echo_info "archiving extra modules..."
    tar -C "${TMP_MOD_DIR}/lib/modules" -zcf "modules-extra-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar.gz" .
fi
if [ -e "${TMP_MOD_DIR}/lib/firmware" ]; then
    echo_info "detected firmwares kernel version: $(ls ${TMP_MOD_DIR}/lib/firmware)"
    echo_info "archiving firmwares..."
    tar -C "${TMP_MOD_DIR}/lib/firmware" -zcf "firmware-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar.gz" .
fi
echo_info "finished"
