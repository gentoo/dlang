# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/dlang-community/dfmt"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
LIBDPARSE="fe6d1e38fb4fc04323170389cfec67ed7fd4e24a"
ALLOCATOR="ae237cabd1843774cc78aad0729c914a3dd579db"
SRC_URI="
	https://github.com/dlang-community/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/dlang-community/stdx-allocator/archive/${ALLOCATOR}.tar.gz -> stdx-allocator-${ALLOCATOR}.tar.gz
	"

DLANG_COMPAT=( dmd-2_{106..107} gdc-13 ldc2-1_{35..36} )

inherit dlang-single bash-completion-r1

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}

src_prepare() {
	default

	mkdir bin || die "Failed to create 'bin' directory."
	cat > bin/githash.txt << EOF
v${PV}
EOF
}

src_compile() {
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

	dlang_compile_bin bin/dfmt "${sourceFiles[@]}"
}

src_test() {
	cd tests || die

	dlang_compile_bin "run_tests" "test.d"
	./run_tests || die "Tests failed"
	# Note, we're missing the unittests in the main binary.
	# See make target bin/dfmt-test.
}

src_install() {
	dobin bin/dfmt
	dodoc README.md LICENSE.txt
	dobashcomp bash-completion/completions/dfmt
}
