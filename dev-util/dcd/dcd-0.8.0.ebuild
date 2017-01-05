# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

DESCRIPTION="Auto-complete program for the D programming language"
HOMEPAGE="https://github.com/Hackerpilot/DCD"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="x86 amd64"
IUSE="systemd"

CONTAINERS="c9853bbca9f0840df32a46edebbb9b17c8216cd4"
ALLOCATOR="e22d5a730db78e54e344e6b003b948a401ad7197"
DSYMBOL="f6aac6cab1ffebdc2a56321f0c5fed2c896f38c4"
LIBDPARSE="516a053c9b16d05aee30d2606a88b7f815cd55df"
MSGPACK="878fcb1852160d1c3d206df933f6becba18aa222"
SRC_URI="
	https://github.com/Hackerpilot/DCD/archive/v${PV}.tar.gz -> DCD-${PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/Hackerpilot/experimental_allocator/archive/${ALLOCATOR}.tar.gz -> experimental_allocator-${ALLOCATOR}.tar.gz
	https://github.com/Hackerpilot/dsymbol/archive/${DSYMBOL}.tar.gz -> dsymbol-${DSYMBOL}.tar.gz
	https://github.com/Hackerpilot/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"
S="${WORKDIR}/DCD-${PV}"

DLANG_VERSION_RANGE="2.067-"
DLANG_PACKAGE_TYPE="single"

inherit dlang systemd

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../containers-${CONTAINERS}            containers                        || die
	mv -T ../experimental_allocator-${ALLOCATOR} containers/experimental_allocator || die
	mv -T ../dsymbol-${DSYMBOL}                  dsymbol                           || die
	mv -T ../libdparse-${LIBDPARSE}              libdparse                         || die
	mv -T ../msgpack-d-${MSGPACK}                msgpack-d                         || die
	# Stop makefile from executing git to write an unused githash.txt
	touch githash || die "Could not generate githash"
	# Phobos 2.069 comes with allocators and would result in conflicting modules when linked as shared library.
	dlang_phobos_level 2.069 && rm -rf containers/experimental_allocator
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
