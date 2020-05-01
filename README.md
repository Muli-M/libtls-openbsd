libtls-openbsd
---------------

This repository creates a site-local binary Debian/Ubuntu package
providing standalone `libtls` from [portable LibreSSL](https://github.com/libressl-portable/portable) built with OpenSSL.
One might find it useful for porting applications from OpenBSD to Linux.

The following packages are needed to build it on Ubuntu:
    build-essential, make, git, autoconf, libtool, dpkg-dev, git-buildpackage, fakeroot, libssl-dev

Just type `make` to create .deb package.

