# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/dlang-community/dfmt"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 x86"
LIBDPARSE="9aefc9c5e6e1495aca094d5c403f35f1052677d1"
ALLOCATOR="ae237cabd1843774cc78aad0729c914a3dd579db"
SRC_URI="
	https://github.com/dlang-community/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/dlang-community/stdx-allocator/archive/${ALLOCATOR}.tar.gz -> stdx-allocator-${ALLOCATOR}.tar.gz
	"

DLANG_VERSION_RANGE="2.075-2.106"
DLANG_PACKAGE_TYPE="single"

inherit dlang bash-completion-r1

src_prepare() {
	mkdir bin || die "Failed to create 'bin' directory."
	cat > bin/githash.txt << EOF
v${PV}
EOF
	dlang_src_prepare
}

d_src_compile() {
	local libdparse_src="../libdparse-${LIBDPARSE}/src"
	local allocator_src="../stdx-allocator-${ALLOCATOR}/source"
	local imports="src ${libdparse_src} ${allocator_src}"
	local string_imports="bin"

	dlang_compile_bin "bin/dfmt" "src/dfmt/main.d" "src/dfmt/config.d" "src/dfmt/editorconfig.d" \
		"src/dfmt/ast_info.d" "src/dfmt/indentation.d" "src/dfmt/tokens.d" "src/dfmt/wrapping.d" \
		"src/dfmt/formatter.d" "src/dfmt/globmatch_editorconfig.d" \
		${libdparse_src}/dparse/lexer.d ${libdparse_src}/dparse/parser.d ${libdparse_src}/dparse/ast.d \
		${libdparse_src}/dparse/rollback_allocator.d ${libdparse_src}/dparse/stack_buffer.d \
		${libdparse_src}/dparse/trivia.d ${libdparse_src}/std/experimental/lexer.d \
		${allocator_src}/stdx/allocator/common.d ${allocator_src}/stdx/allocator/internal.d \
		${allocator_src}/stdx/allocator/mallocator.d ${allocator_src}/stdx/allocator/package.d \
		${allocator_src}/stdx/allocator/gc_allocator.d ${allocator_src}/stdx/allocator/typed.d
}

d_src_test() {
	cd tests && ./test.sh
}

d_src_install() {
	dobin bin/dfmt
	dodoc README.md LICENSE.txt
	dobashcomp bash-completion/completions/dfmt
}
