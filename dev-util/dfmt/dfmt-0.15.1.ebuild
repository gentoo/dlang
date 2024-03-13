# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/dlang-community/dfmt"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 ~arm64 x86"
LIBDPARSE="fe6d1e38fb4fc04323170389cfec67ed7fd4e24a"
ALLOCATOR="ae237cabd1843774cc78aad0729c914a3dd579db"
SRC_URI="
	https://github.com/dlang-community/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/dlang-community/stdx-allocator/archive/${ALLOCATOR}.tar.gz -> stdx-allocator-${ALLOCATOR}.tar.gz
	"

DLANG_VERSION_RANGE="2.100-2.106"
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
	local srcDirectories=(
		"${S}/src"
		"${S}/${libdparse_src}"
		"${S}/${allocator_src}"
	)
	local sourceFile sourceFiles=()
	while read -r -d '' sourceFile; do
		sourceFiles+=("${sourceFile}")
	done < <(find "${srcDirectories[@]}" -name '*.d' -print0)

	dlang_compile_bin "bin/dfmt" "${sourceFiles[@]}"
}

d_src_test() {
	cd tests || die

	dlang_compile_bin "run_tests" "test.d"
	./run_tests || die "Tests failed"
}

d_src_install() {
	dobin bin/dfmt
	dodoc README.md LICENSE.txt
	dobashcomp bash-completion/completions/dfmt
}
