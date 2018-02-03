# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/dlang-community/dfmt"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="x86 amd64"
LIBDPARSE="db1a9364b1815eec82ac853a9765d5532571db43"
ALLOCATOR="2.70.0-b1"
SRC_URI="
	https://github.com/dlang-community/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/Hackerpilot/experimental_allocator/archive/v${ALLOCATOR}.tar.gz -> experimental_allocator-${ALLOCATOR}.tar.gz
	"

DLANG_VERSION_RANGE="2.067-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T "../libdparse-${LIBDPARSE}"              libdparse                        || die
	mv -T "../experimental_allocator-${ALLOCATOR}" libdparse/experimental_allocator || die

	# Phobos 2.069 comes with allocators and would result in conflicting modules when linked as shared library.
	dlang_phobos_level 2.069 && rm -rf libdparse/experimental_allocator
	# Apply patches
	dlang_src_prepare
}

d_src_compile() {
	mkdir bin || die "Failed to create 'bin' directory."

	local imports="src libdparse/src libdparse/experimental_allocator/src"
	local versions="Have_dfmt Have_libdparse"
	if dlang_phobos_level 2.069; then
		local allocator=
	else
		local allocator="
			libdparse/experimental_allocator/src/std/experimental/allocator/common.d
			libdparse/experimental_allocator/src/std/experimental/allocator/gc_allocator.d
			libdparse/experimental_allocator/src/std/experimental/allocator/mallocator.d
			libdparse/experimental_allocator/src/std/experimental/allocator/package.d
			libdparse/experimental_allocator/src/std/experimental/allocator/typed.d
		"
	fi

	dlang_compile_bin "bin/dfmt" "src/dfmt/*.d" "${allocator}" \
		"libdparse/src/std/experimental/lexer.d" \
		"libdparse/src/dparse/ast.d" \
		"libdparse/src/dparse/lexer.d" \
		"libdparse/src/dparse/parser.d"
}

d_src_test() {
	cd tests && ./test.sh
}

d_src_install() {
	dobin bin/dfmt
	dodoc README.md LICENSE.txt
}
