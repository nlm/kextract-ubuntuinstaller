docker-kextract
===============

Script using docker to extract debian-installer kernels and modules
for different architectures. It downloads the kernel and initrds from
debian mirrors and extracts the content of initrd to repack only the
modules in a tar archive.

How to Use
----------

### Simple mode

Download binaries from latest
[Github release](https://github.com/nlm/docker-kextract/releases/latest)

### Auto mode

```
./run.sh ARCH DIST
```

### Manual mode

```
mkdir ./workdir
docker run --rm -ti -v $(pwd)/workdir:/workdir nlimage/kextract ARCH DIST
```

Supported Distributions / Architectures
---------------------------------------

- jessie
  - amd64
  - arm64
  - armhf
  - i386
  - powerpc
  - ppc64el
- stretch
  - amd64
  - arm64
  - armhf
  - i386
  - ppc64el

Other combinations may work but are untested
