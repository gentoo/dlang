# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Auto-complete program for the D programming language"
HOMEPAGE="https://github.com/dlang-community/DCD"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="systemd"

CONTAINERS="6c5504cc80b75192b24cebe93209521c03f806d8"
DSYMBOL="5b90412457ac5f1d67c04e4da01587edfd529ad5"
LIBDPARSE="ee0fa01ab74b6bf27bed3c7bdb9d6fb789963342"
ALLOCATOR="7487970b58f4a2c0d495679329a8a2857111f3fd"
MSGPACK="500940918243cf0468028e552605204c6aa46807"
SRC_URI="
	https://github.com/dlang-community/DCD/archive/v${PV}.tar.gz -> DCD-${PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/dlang-community/dsymbol/archive/${DSYMBOL}.tar.gz -> dsymbol-${DSYMBOL}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/dlang-community/stdx-allocator/archive/${ALLOCATOR}.tar.gz -> stdx-allocator-${ALLOCATOR}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"
S="${WORKDIR}/DCD-${PV}"

DLANG_VERSION_RANGE="2.075-"
DLANG_PACKAGE_TYPE="single"

inherit dlang systemd

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../stdx-allocator-${ALLOCATOR} stdx-allocator/source || die
	mv -T ../containers-${CONTAINERS}    containers            || die
	mv -T ../dsymbol-${DSYMBOL}          dsymbol               || die
	mv -T ../libdparse-${LIBDPARSE}      libdparse             || die
	mv -T ../msgpack-d-${MSGPACK}        msgpack-d             || die
	# Stop makefile from executing git to write an unused githash.txt
	touch githash githash.txt || die "Could not generate githash"
	# Apply patches
	dlang_src_prepare
}

d_src_compile() {
	# Build client & server with the requested Dlang compiler
	local flags="$DCFLAGS $LDFLAGS $DLANG_VERSION_FLAG=built_with_dub -Icontainers/src -Idsymbol/src -Ilibdparse/src -Imsgpack-d/src -Isrc"
	case "$DLANG_VENDOR" in
	DigitalMars)
		emake \
			DMD="$DC" \
			DMD_CLIENT_FLAGS="$flags -ofbin/dcd-client" \
			DMD_SERVER_FLAGS="$flags -ofbin/dcd-server" \
			dmd
		;;
	GNU)
		emake \
			GDC="$DC" \
			GDC_CLIENT_FLAGS="$flags -obin/dcd-client" \
			GDC_SERVER_FLAGS="$flags -obin/dcd-server" \
			gdc
		;;
	LDC)
		mkdir -p bin || die "Could not create 'bin' output directory."
		emake \
			LDC="$DC" \
			LDC_CLIENT_FLAGS="$flags -g -of=bin/dcd-client" \
			LDC_SERVER_FLAGS="$flags" \
			ldc
		;;
	*)
		die "Unsupported compiler vendor: $DLANG_VENDOR"
		;;
	esac
	# Write system include paths of host compiler into dcd.conf
	dlang_system_imports > dcd.conf
}

d_src_test() {
	# The tests don't work too well in a sandbox, e.g. multiple permission denied errors.
	cd tests
	#./run_tests.sh || die "Tests failed"
}

d_src_install() {
	dobin bin/dcd-server
	dobin bin/dcd-client
	use systemd && systemd_douserunit "${FILESDIR}"/dcd-server.service
	insinto /etc
	doins dcd.conf
	dodoc README.md
	doman man1/dcd-client.1 man1/dcd-server.1
}

pkg_postinst() {
	use systemd && elog "A systemd user service for 'dcd-server' has been installed."
}
