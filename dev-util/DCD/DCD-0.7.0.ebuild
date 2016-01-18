# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="The Dlang Completion Daemon is an auto-complete program for the D programming language"
HOMEPAGE="https://github.com/Hackerpilot/DCD"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="x86 amd64"
CONTAINERS="04158caa5d651562ac99d40cd9aec2cd06a15508"
ALLOCATOR="cd8196a5b063b9019ea5529239da3181cc4fdc4f"
DSYMBOL="c9ac0cbf1a4496c2c015829bf08fd96c08c53ff7"
LIBDPARSE="d5e1d359b63d011608af2638f224f54912bd4401"
MSGPACK="878fcb1852160d1c3d206df933f6becba18aa222"
SRC_URI="
	https://github.com/Hackerpilot/DCD/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/Hackerpilot/experimental_allocator/archive/${ALLOCATOR}.tar.gz -> experimental_allocator-${ALLOCATOR}.tar.gz
	https://github.com/Hackerpilot/dsymbol/archive/${DSYMBOL}.tar.gz -> dsymbol-${DSYMBOL}.tar.gz
	https://github.com/Hackerpilot/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"

DLANG_VERSION_RANGE="2.068-"
DLANG_PACKAGE_TYPE="single"

inherit dlang systemd

src_prepare() {
	echo "" > githash.txt || die "Could not generate githash.txt"
}

d_src_compile() {
	local imports="src ../containers-${CONTAINERS}/src ../experimental_allocator-${ALLOCATOR}/src"
	local string_imports="."

	mkdir -p bin || die "Failed to create 'bin' directory."

	dlang_compile_bin bin/dcd-server\
		src/common/{constants,messages}.d\
		src/server/{autocomplete,server}.d\
		../containers-${CONTAINERS}/src/containers/{unrolledlist,hashset,ttree}.d\
		../containers-${CONTAINERS}/src/containers/internal/{element_type,hash,node,storage_type}.d\
		../dsymbol-${DSYMBOL}/src/dsymbol/{cache_entry,deferred,import_,modulecache,scope_,semantic,string_interning,symbol,type_lookup}.d\
		../dsymbol-${DSYMBOL}/src/dsymbol/builtin/{names,symbols}.d\
		../dsymbol-${DSYMBOL}/src/dsymbol/conversion/{first,package,second}.d\
		../experimental_allocator-${ALLOCATOR}/src/std/experimental/allocator/{common,gc_allocator,mallocator,package,typed}.d\
		../experimental_allocator-${ALLOCATOR}/src/std/experimental/allocator/building_blocks/allocator_list.d\
		../libdparse-${LIBDPARSE}/src/std/lexer.d\
		../libdparse-${LIBDPARSE}/src/std/d/{ast,formatter,lexer,parser}.d\
		../msgpack-d-${MSGPACK}/src/msgpack.d

	dlang_compile_bin bin/dcd-client\
		src/client/client.d\
		src/common/messages.d\
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