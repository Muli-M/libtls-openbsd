# Makefile for the libtls-openbsd package

MULI_TAG?=1.0
LIBRESSL_VERSION=3.0.2
ARCH=`dpkg --print-architecture`
DESTDIR=$(shell pwd)/debian/tmp
ACLOCAL?=aclocal
LIBTOOLIZE?=libtoolize
AUTOMAKE?=automake
AUTOCONF?=autoconf

debian: makefile debian/control v$(LIBRESSL_VERSION).tar.gz
	rm -rf debian/tmp
	mkdir -p debian/tmp/DEBIAN
	mkdir -p debian/tmp/usr/local/bin
	mkdir -p debian/tmp/usr/local/include
	mkdir -p debian/tmp/usr/local/lib
	cd portable-$(LIBRESSL_VERSION); \
	/bin/sh update.sh ;\
	mkdir -p libtls-standalone/man ; \
	cp ../update-standalone.sh . ; \
	cp ../tls_compat.h libtls-standalone/include ; \
	cp ../tls_compat.c libtls-standalone/src ; \
	/bin/sh update-standalone.sh ; \
	cd libtls-standalone ; \
	$(ACLOCAL) ; \
	$(LIBTOOLIZE) --copy --force ; \
	$(AUTOMAKE) --foreign --force-missing --add-missing --copy Makefile ; \
	$(AUTOMAKE) -a --copy ; \
	$(AUTOCONF) ; \
	/bin/sh configure --prefix=/usr/local --sysconfdir=/usr/local/etc --mandir=/usr/local/man --infodir=/usr/local/info --localstatedir=/var ; \
	make -j 2 -f Makefile ; \
	DESTDIR=${DESTDIR} make -f Makefile install

	# generate changelog from git log
	gbp dch --ignore-branch --git-author
	sed -i "/UNRELEASED;/s/unknown/${MULI_TAG}/" debian/changelog
	# generate dependencies
	dpkg-shlibdeps -ldebian/tmp/usr/local/lib debian/tmp/usr/local/lib/*.so
	# generate symbols file
	dpkg-gensymbols
	# generate md5sums file
	find debian/tmp/ -type f -exec md5sum '{}' + | grep -v DEBIAN | sed s#debian/tmp/## > debian/tmp/DEBIAN/md5sums
	# control
	dpkg-gencontrol -v${LIBRESSL_VERSION}-${MULI_TAG}

	fakeroot dpkg-deb --build debian/tmp .

v$(LIBRESSL_VERSION).tar.gz:
	wget -c https://github.com/libressl-portable/portable/archive/v$(LIBRESSL_VERSION).tar.gz
	tar -xzvf v$(LIBRESSL_VERSION).tar.gz

clean:
	rm -f *~ *.deb v*.tar.gz
	rm -rf debian/tmp portable-*

.DEFAULT:
	make -f Makefile $@

.PHONY: clean debian

