# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Swiss-army knife for D source code"
HOMEPAGE="https://github.com/dlang-community/D-Scanner"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

CONTAINERS="5d85484707d9bb6bae374f352231e633518efe5a"
DSYMBOL="3f7eaa1b1e6dd0c5e14d500d0b3d4ba1e1e41138"
INIFILED="cecaff8037a60db2a51c9bded4802c87d938a44e"
LIBDDOC="476c0964ee173d7574155aa2a9caa2bc019a3754"
LIBDPARSE="086cf06051bb1f33c94891ba6c39a57f164ee296"
ALLOCATOR="b7778fd6bf5f9aaaa87dd27f989cefbf9b3b365f"
GITHUB_URI="https://codeload.github.com"
SRC_URI="
	${GITHUB_URI}/dlang-community/${PN}/tar.gz/v${PV} -> ${P}.tar.gz
	${GITHUB_URI}/dlang-community/containers/tar.gz/${CONTAINERS} -> containers-${CONTAINERS}.tar.gz
	${GITHUB_URI}/dlang-community/dsymbol/tar.gz/${DSYMBOL} -> dsymbol-${DSYMBOL}.tar.gz
	${GITHUB_URI}/burner/inifiled/tar.gz/${INIFILED} -> inifiled-${INIFILED}.tar.gz
	${GITHUB_URI}/economicmodeling/libddoc/tar.gz/${LIBDDOC} -> libddoc-${LIBDDOC}.tar.gz
	${GITHUB_URI}/dlang-community/libdparse/tar.gz/${LIBDPARSE} -> libdparse-${LIBDPARSE}.tar.gz
	${GITHUB_URI}/dlang-community/stdx-allocator/tar.gz/${ALLOCATOR} -> stdx-allocator-${ALLOCATOR}.tar.gz
	"
S="${WORKDIR}/D-Scanner-${PV}"

DLANG_VERSION_RANGE="2.075-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

src_prepare() {
	mkdir bin || die "Failed to create 'bin' directory."
	# Stop makefile from executing git to write an unused githash.txt
	touch githash githash.txt || die "Could not generate githash"
	# Apply patches
	dlang_src_prepare
}

compile_dscanner() {
	local container_src="../containers-${CONTAINERS}/src"
	local dsymbol_src="../dsymbol-${DSYMBOL}/src"
	local inifiled_src="../inifiled-${INIFILED}/source"
	local libddoc_src="../libddoc-${LIBDDOC}/src"
	local libdparse_src="../libdparse-${LIBDPARSE}/src"
	local allocator_src="../stdx-allocator-${ALLOCATOR}/source"
	local imports="src ${container_src} ${dsymbol_src} ${inifiled_src} ${libddoc_src} ${libdparse_src} ${allocator_src}"
	local string_imports="."
	local versions="StdLoggerDisableWarning"
	use debug && versions="${versions} dparse_verbose"

	local src=`find src -name "*.d" -printf "%p "`
	local lib_src=`find ${container_src} ${dsymbol_src} ${inifiled_src} ${libddoc_src} ${libdparse_src} ${allocator_src} -name "*.d" -printf "%p "`

	if [ "$1" == "unittest" ]; then
		dlang_compile_lib_a bin/dscanner-unittest-lib.a "${lib_src}"
		DCFLAGS="${DCFLAGS} ${DLANG_UNITTEST_FLAG}" dlang_compile_bin bin/dscanner-unittest bin/dscanner-unittest-lib.a "${src}"
	else
		dlang_compile_bin bin/dscanner "${src} ${lib_src}"
	fi
}

d_src_compile() {
	compile_dscanner
}

d_src_test() {
	compile_dscanner unittest
	bin/dscanner-unittest || die
}

d_src_install() {
	dobin bin/dscanner
	dodoc README.md LICENSE_1_0.txt
}
