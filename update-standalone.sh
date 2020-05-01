#!/bin/sh
set -e

# setup source paths
CWD=`pwd`
OPENBSD_SRC=$CWD/openbsd/src
libtls_src=$OPENBSD_SRC/lib/libtls

CP='cp -p'
GREP='grep'
if [ -x /opt/csw/bin/ggrep ]; then
	GREP='/opt/csw/bin/ggrep'
fi



# add the libtls symbol export list
$GREP '^[A-Za-z0-9_]' < $libtls_src/Symbols.list > libtls-standalone/tls.sym

add_man_links() {
	filter=$1
	dest=$2
	echo "install-data-hook:" >> $dest
	for i in `$GREP $filter man/links`; do
		IFS=","; set $i; unset IFS
		if [ "$2" != "" ]; then
			echo "	ln -sf \"$1\" \"\$(DESTDIR)\$(mandir)/man3/$2\"" >> $dest
		fi
	done
	echo "" >> $dest
	echo "uninstall-local:" >> $dest
	for i in `$GREP $filter man/links`; do
		IFS=","; set $i; unset IFS
		if [ "$2" != "" ]; then
			echo "	-rm -f \"\$(DESTDIR)\$(mandir)/man3/$2\"" >> $dest
		fi
	done
}

# copy manpages
echo "copying manpages"
echo EXTRA_DIST = CMakeLists.txt > libtls-standalone/man/Makefile.am
echo dist_man3_MANS = >> libtls-standalone/man/Makefile.am
echo dist_man5_MANS = >> libtls-standalone/man/Makefile.am

(cd libtls-standalone/man
	for i in `ls -1 $libtls_src/man/*.3 | sort`; do
		NAME=`basename "$i"`
		$CP $i .
		echo "dist_man3_MANS += $NAME" >> Makefile.am
	done

)
add_man_links ^tls_ libtls-standalone/man/Makefile.am

sed -i s/LIBC_CRYPTO_COMPAT/CRYPTO_COMPAT/ libtls-standalone/configure.ac
if ! $GREP -q am.common libtls-standalone/Makefile.am; then
    sed -i '1 i\include ../Makefile.am.common' libtls-standalone/Makefile.am
fi
if ! $GREP -q am.common libtls-standalone/src/Makefile.am; then
    sed -i '1 i\include ../../Makefile.am.common' libtls-standalone/src/Makefile.am
    sed -i 's/AM_CFLAGS =/AM_CFLAGS +=/' libtls-standalone/src/Makefile.am
    sed -i '18 i\libtls_la_SOURCES += tls_compat.c' libtls-standalone/src/Makefile.am
    sed -i '19 a\noinst_HEADERS += tls_compat.h' libtls-standalone/src/Makefile.am
fi
if ! $GREP -q string.h libtls-standalone/src/tls.c; then
    sed -i '24 i\#include <string.h>' libtls-standalone/src/tls.c
fi
if ! $GREP -q string.h libtls-standalone/src/tls_bio_cb.c; then
    sed -i '21 i\#include <string.h>' libtls-standalone/src/tls_bio_cb.c
fi
if ! $GREP -q string.h libtls-standalone/src/tls_client.c; then
    sed -i '28 i\#include <string.h>' libtls-standalone/src/tls_client.c
fi
if ! $GREP -q string.h libtls-standalone/src/tls_server.c; then
    sed -i '21 i\#include <string.h>' libtls-standalone/src/tls_server.c
fi
if ! $GREP -q tls_compat.h libtls-standalone/src/tls_server.c; then
    sed -i '29 i\#include "tls_compat.h"' libtls-standalone/src/tls_server.c
fi
if ! $GREP -q string.h libtls-standalone/src/tls_config.c; then
    sed -i '25 i\#include <string.h>' libtls-standalone/src/tls_config.c
fi
if ! $GREP -q string.h libtls-standalone/src/tls_util.c; then
    sed -i '24 i\#include <string.h>' libtls-standalone/src/tls_util.c
fi
sed -i '/static BIO_METHOD bio_cb_method/,/};/d' libtls-standalone/src/tls_bio_cb.c
sed -i '/return (&bio/c \
    BIO_METHOD *m = BIO_meth_new(BIO_TYPE_MEM, "libtls_callbacks");\
    BIO_meth_set_write(m, bio_cb_write);\
    BIO_meth_set_read(m, bio_cb_read);\
    BIO_meth_set_puts(m, bio_cb_puts);\
    BIO_meth_set_ctrl(m, bio_cb_ctrl);\
    return m;
' libtls-standalone/src/tls_bio_cb.c
sed -i '/(long)bio/c \
       		ret = (long)BIO_get_shutdown(bio);
' libtls-standalone/src/tls_bio_cb.c
sed -i '/shutdown = /c \
       		BIO_set_shutdown(bio, (int)num);
' libtls-standalone/src/tls_bio_cb.c
sed -i '/next_bio/c \
		ret = BIO_ctrl(BIO_next(bio), cmd, num, ptr);
' libtls-standalone/src/tls_bio_cb.c
sed -i '/bio->ptr;/c \
	struct tls *ctx = BIO_get_data(bio);
' libtls-standalone/src/tls_bio_cb.c
sed -i '/bio->ptr/c \
	BIO_set_data(bio, ctx);
' libtls-standalone/src/tls_bio_cb.c
sed -i '/bio->init/c \
	BIO_set_init(bio, 1);
' libtls-standalone/src/tls_bio_cb.c
sed -i '/X509_VERIFY_PARAM_set_flags.store/c \
		X509_VERIFY_PARAM_set_flags(X509_STORE_get0_param(store),
' libtls-standalone/src/tls.c
sed -i '/X509_VERIFY_PARAM_set_flags.ssl_ctx/c \
		X509_VERIFY_PARAM_set_flags(SSL_CTX_get0_param(ssl_ctx),
' libtls-standalone/src/tls.c
if ! $GREP -q tls_compat.h libtls-standalone/src/tls.c; then
    sed -i '37 i\#include "tls_compat.h"' libtls-standalone/src/tls.c
fi
sed -i 's/ASN1_STRING_data/ASN1_STRING_get0_data/' libtls-standalone/src/tls_verify.c

