#!/bin/sh
DOCKERIMAGE="${KEXTRACT_DOCKERIMAGE:-kextract}"
docker build -t "${DOCKERIMAGE}" .

for dist in xenial yakkety
do
  for arch in amd64 arm64 armhf i386 powerpc ppc64el
  do
    docker run --rm -ti -v "$(pwd)/dist:/workdir" "${DOCKERIMAGE}" "$arch" "$dist"
  done
done
