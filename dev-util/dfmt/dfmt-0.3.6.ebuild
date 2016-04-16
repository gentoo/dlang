# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/Hackerpilot/dfmt"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="x86 amd64"
LIBDPARSE="ccb3d98996f89cfb35799aee6358e640f6f71f67"
SRC_URI="
	https://github.com/Hackerpilot/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/Hackerpilot/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	"

DLANG_VERSION_RANGE="2.066-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

d_src_compile() {
	local imports="src ../libdparse-${LIBDPARSE}/src"
	local versions="Have_dfmt Have_libdparse"

	mkdir bin || die "Failed to create 'bin' directory."
	dlang_compile_bin "bin/dfmt" "src/dfmt/*.d" \
		"../libdparse-${LIBDPARSE}/src/std/allocator.d" \
		"../libdparse-${LIBDPARSE}/src/std/lexer.d" \
		"../libdparse-${LIBDPARSE}/src/std/d/ast.d" \
		"../libdparse-${LIBDPARSE}/src/std/d/lexer.d" \
		"../libdparse-${LIBDPARSE}/src/std/d/parser.d"
}

d_src_test() {
	cd tests && ./test.sh
}

d_src_install() {
	dobin bin/dfmt
	dodoc README.md
}
