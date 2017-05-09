# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Swiss-army knife for D source code"
HOMEPAGE="https://github.com/dlang-community/D-Scanner"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

ALLOCATOR="131739dce3038ccd6d762f3dd92d3718fbe5fc5f"
CONTAINERS="2892cfc1e7a205d4f81af3970cbb53e4f365a765"
DSYMBOL="d22c9714a60ac05cb32db938e81a396cffb5ffa6"
INIFILED="e4f63f126ddddb3e496574fec0f76b24e61b1d51"
LIBDPARSE="ca51bd13cf68646eaf9d6987db100cc3b288cffe"
GITHUB_URI="https://codeload.github.com"
SRC_URI="
	${GITHUB_URI}/Hackerpilot/experimental_allocator/tar.gz/${ALLOCATOR} -> experimental_allocator-${ALLOCATOR}.tar.gz
	${GITHUB_URI}/dlang-community/${PN}/tar.gz/v${PV} -> ${P}.tar.gz
	${GITHUB_URI}/economicmodeling/containers/tar.gz/${CONTAINERS} -> containers-${CONTAINERS}.tar.gz
	${GITHUB_URI}/dlang-community/dsymbol/tar.gz/${DSYMBOL} -> dsymbol-${DSYMBOL}.tar.gz
	${GITHUB_URI}/burner/inifiled/tar.gz/${INIFILED} -> inifiled-${INIFILED}.tar.gz
	${GITHUB_URI}/dlang-community/libdparse/tar.gz/${LIBDPARSE} -> libdparse-${LIBDPARSE}.tar.gz
	"
S="${WORKDIR}/D-Scanner-${PV}"

DLANG_VERSION_RANGE="2.068-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../containers-${CONTAINERS}            containers                       || die
	mv -T ../dsymbol-${DSYMBOL}                  dsymbol                          || die
	mv -T ../inifiled-${INIFILED}                inifiled                         || die
	mv -T ../libdparse-${LIBDPARSE}              libdparse                        || die
	mv -T ../experimental_allocator-${ALLOCATOR} libdparse/experimental_allocator || die
	# Phobos 2.069 comes with allocators and would result in conflicting modules when linked as shared library.
	dlang_phobos_level 2.069 && rm -rf libdparse/experimental_allocator
	# Stop makefile from executing git to write an unused githash.txt
	touch githash githash.txt || die "Could not generate githash"
	# Apply patches
	dlang_src_prepare
}

compile_dscanner() {
	local paths="containers/src dsymbol/src inifiled/source/ libdparse/src/ src/"
	dlang_phobos_level 2.069 || paths="libdparse/experimental_allocator/src ${paths}"
	local src=`find ${paths} -name "*.d" -printf "%p "`
	local string_imports="."
	local versions="StdLoggerDisableWarning"
	use debug && versions="${versions} dparse_verbose"

	if [ "$1" == "unittest" ]; then
		DCFLAGS="${DCFLAGS} ${DLANG_UNITTEST_FLAG}" dlang_compile_bin bin/dscanner-unittest "${src}"
		bin/dscanner-unittest
	else
		dlang_compile_bin bin/dscanner "${src}"
	fi
}

d_src_compile() {
	mkdir bin || die "Failed to create 'bin' directory."
	compile_dscanner
}

d_src_test() {
	compile_dscanner unittest
}

d_src_install() {
	dobin bin/dscanner
	dodoc README.md LICENSE_1_0.txt
}
