# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/dlang-community/dfmt"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~x86 ~amd64"
LIBDPARSE="687c0ca751747ebe498c183da1a3ee3119d57932"
SRC_URI="
	https://github.com/dlang-community/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	"

DLANG_VERSION_RANGE="2.069-"
DLANG_PACKAGE_TYPE="single"

inherit dlang bash-completion-r1

src_prepare() {
	mkdir views || die "Failed to create 'views' directory."
	cat > views/VERSION << EOF
v${PV}
EOF
	dlang_src_prepare
}

d_src_compile() {
	mkdir bin || die "Failed to create 'bin' directory."

	local libdparse_src="../libdparse-${LIBDPARSE}/src"
	local imports="src ${libdparse_src}"
	local string_imports="views"

	dlang_compile_bin "bin/dfmt" "src/dfmt/main.d" "src/dfmt/config.d" "src/dfmt/editorconfig.d" \
		"src/dfmt/ast_info.d" "src/dfmt/indentation.d" "src/dfmt/tokens.d" "src/dfmt/wrapping.d" \
		"src/dfmt/formatter.d" "src/dfmt/globmatch_editorconfig.d" \
		${libdparse_src}/dparse/lexer.d ${libdparse_src}/dparse/parser.d ${libdparse_src}/dparse/ast.d \
		${libdparse_src}/dparse/rollback_allocator.d ${libdparse_src}/dparse/stack_buffer.d \
		${libdparse_src}/std/experimental/lexer.d
}

d_src_test() {
	cd tests && ./test.sh
}

d_src_install() {
	dobin bin/dfmt
	dodoc README.md LICENSE.txt
	dobashcomp bash-completion/completions/dfmt
}
