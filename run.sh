#!/bin/sh -eu
usage()
{
    echo "usage: $0 amd64|arm64|armel|armhf|i386|powerpc|ppc64el xenial"
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

ARCH="${1}"
DIST="${2}"

DOCKERIMAGE="${KEXTRACT_DOCKERIMAGE:-kextract}"
WORKDIR="${KEXTRACT_WORKDIR:-$(pwd)/workdir}"

docker build -t "${DOCKERIMAGE}" .
docker run --rm -ti -v "${WORKDIR}:/workdir" "${DOCKERIMAGE}" "${ARCH}" "${DIST}"
