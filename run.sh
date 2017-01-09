#!/bin/sh -eu
DOCKERIMAGE=${KEXTRACT:-kextract}
WORKDIR=${KEXTRACT_WORKDIR:-$(pwd)/workdir}
ARCH=${1:-${KEXTRACT_ARCH:-amd64}}

usage()
{
    echo "usage: $0 amd64|arm64|armel|armhf|i386|powerpc|ppc64el"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

docker build -t ${DOCKERIMAGE} .
[ ! -d $WORKDIR ] && mkdir -p ${WORKDIR}
docker run --rm -ti -v ${WORKDIR}:/workdir ${DOCKERIMAGE} ${ARCH}
