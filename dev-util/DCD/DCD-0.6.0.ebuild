# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="The Dlang Completion Daemon is an auto-complete program for the D programming language"
HOMEPAGE="https://github.com/Hackerpilot/DCD"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="x86 amd64"
CONTAINERS="d732a67e76f60fd037547c3ffe8776c6deda6bab"
LIBDPARSE="32f6d638e38888e1bb11cf43e93fe2d11132a98f"
MSGPACK="878fcb1852160d1c3d206df933f6becba18aa222"
SRC_URI="
	https://github.com/Hackerpilot/DCD/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/Hackerpilot/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"

DLANG_VERSION_RANGE="2.066-"
DLANG_PACKAGE_TYPE="single"

inherit dlang systemd

src_prepare() {
	rm "../containers-${CONTAINERS}/src/std/allocator.d" || die "Could not delete std.allocator.d"
	echo "" > githash.txt || die "Could not generate githash.txt"
}

d_src_compile() {
	local imports="src ../containers-${CONTAINERS}/src ../libdparse-${LIBDPARSE}/src ../msgpack-d-${MSGPACK}/src"
	local string_imports="."

	mkdir -p bin || die "Failed to create 'bin' directory."

	dlang_compile_bin bin/dcd-server\
		src/{actypes,autocomplete,constants,messages,modulecache,semantic,server,string_interning,stupidlog}.d\
		src/conversion/{astconverter,first,second,third}.d\
		../containers-${CONTAINERS}/src/containers/ttree.d\
		../containers-${CONTAINERS}/src/containers/internal/node.d\
		../containers-${CONTAINERS}/src/memory/{allocators,appender}.d\
		../libdparse-${LIBDPARSE}/src/std/{allocator,lexer}.d\
		../libdparse-${LIBDPARSE}/src/std/d/{ast,formatter,lexer,parser}.d\
		../msgpack-d-${MSGPACK}/src/msgpack.d\
		../containers-${CONTAINERS}/src/containers/{unrolledlist,hashset}.d\
		../containers-${CONTAINERS}/src/containers/internal/{hash,storage_type}.d

	dlang_compile_bin bin/dcd-client\
		src/{client,messages,stupidlog}.d\
		../msgpack-d-${MSGPACK}/src/msgpack.d

	dlang_system_imports > dcd.conf
}

d_src_install() {
	dobin bin/dcd-server
	dobin bin/dcd-client
	systemd_dounit "${FILESDIR}"/dcd-server.service
	insinto /etc
	doins "${FILESDIR}"/dcd-server.conf
	doins dcd.conf
	dodoc README.md
}

pkg_postinst() {
	systemd_is_booted && elog "A systemd service for 'dcd-server' has been installed."
}