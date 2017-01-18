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

COMPRESSOR="xz -f -9"

echo_info "repo=$UBUNTU_REPO"
echo_info "installer=$UBUNTU_INSTALLER"
echo_info "pkgidx=$UBUNTU_PKGIDX"
echo_info "arch=$UBUNTU_ARCH"
echo_info "dist=$UBUNTU_DIST"
echo_info "compressor=$COMPRESSOR"

echo_info "downloading linux image..."
wget -q "${UBUNTU_INSTALLER}/$LINUX" -O "vmlinuz-${UBUNTU_DIST}-${UBUNTU_ARCH}"
echo_info "downloading initrd..."
wget -q "${UBUNTU_INSTALLER}/$INITRD" -O "initrd.gz"
echo_info "extracting modules from initrd..."
gunzip < "initrd.gz" | cpio -id 'lib/modules/*'
echo_info "archiving base modules..."
kernel_version=$(ls -1 lib/modules | head -n 1)
echo_info "detected kernel version: ${kernel_version}"
tar -C "lib/modules" -cf "modules-base-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar" .
echo_info "compressing archive..."
$COMPRESSOR "modules-base-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar"
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
    pkg_name="$(basename $path | cut -d'-' -f 1)"
    pkg_dir="${TMP_MOD_DIR}/${pkg_file}"
    echo_subinfo "downloading ${pkg_url}..."
    wget -q "${pkg_url}" -O "${pkg_file}"
    echo_subinfo "extracting ${pkg_file}..."
    mkdir -p "${pkg_dir}"
    dpkg --extract "${pkg_file}" "${pkg_dir}"
    for asset_type in modules firmware; do
        if [ -e "${pkg_dir}/lib/${asset_type}" ]; then
            echo_info "${pkg_name} ${asset_type} kernel version: $(ls ${pkg_dir}/lib/${asset_type})"
            echo_info "archiving ${pkg_name} ${asset_type}..."
            tar -C "${pkg_dir}/lib/${asset_type}" -cf "${asset_type}-${pkg_name}-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar" .
            echo_info "compressing archive..."
            $COMPRESSOR "${asset_type}-${pkg_name}-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar"
        fi
#    if [ -e "${pkg_dir}/lib/firmware" ]; then
#        echo_info "firmwares kernel version: $(ls ${pkg_dir}/lib/firmware)"
#        echo_info "archiving $pkg_name firmwares..."
#        tar -C "${pkg_dir}/lib/firmware" -cf "firmware-${pkg_name}-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar" .
#        echo_info "compressing archive..."
#        $COMPRESSOR "firmware-${pkg_name}-${UBUNTU_DIST}-${UBUNTU_ARCH}.tar"
#    fi
    done
    echo_subinfo "cleaning..."
    rm -rf "${pkg_dir}"
done
echo_info "finished"
