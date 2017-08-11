# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Auto-complete program for the D programming language"
HOMEPAGE="https://github.com/dlang-community/DCD"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="x86 amd64"
IUSE="systemd"

CONTAINERS="2892cfc1e7a205d4f81af3970cbb53e4f365a765"
DSYMBOL="e9aae0594739d002009cd34dd3edeb38f1f0893b"
LIBDPARSE="5e81535d0aff4ceec2cbf03f5b02a31ae6d3fec2"
MSGPACK="e6a5a69d2f86f2a0f7f7dad9de7080a55a929e46"
SRC_URI="
	https://github.com/dlang-community/DCD/archive/v${PV}.tar.gz -> DCD-${PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/dlang-community/dsymbol/archive/${DSYMBOL}.tar.gz -> dsymbol-${DSYMBOL}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"
S="${WORKDIR}/DCD-${PV}"

DLANG_VERSION_RANGE="2.069-"
DLANG_PACKAGE_TYPE="single"

inherit dlang systemd

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../containers-${CONTAINERS}            containers                        || die
	mv -T ../dsymbol-${DSYMBOL}                  dsymbol                           || die
	mv -T ../libdparse-${LIBDPARSE}              libdparse                         || die
	mv -T ../msgpack-d-${MSGPACK}                msgpack-d                         || die
	# Stop makefile from executing git to write an unused githash.txt
	touch githash githash.txt || die "Could not generate githash"
	# Apply patches
	dlang_src_prepare
}

d_src_compile() {
	# Build client & server with the requested Dlang compiler
	local flags="$DCFLAGS $LDFLAGS $DLANG_VERSION_FLAG=built_with_dub -Icontainers/experimental_allocator/src -Icontainers/src -Idsymbol/src -Ilibdparse/src -Imsgpack-d/src -Isrc"
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
	cd tests && ./run_tests.sh || die "Tests failed"
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
