# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Swiss-army knife for D source code"
HOMEPAGE="https://github.com/dlang-community/D-Scanner"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE="debug"

CONTAINERS="2892cfc1e7a205d4f81af3970cbb53e4f365a765"
DSYMBOL="6920a0489fbef44f105cdfb76d426a03ae14259a"
INIFILED="35f8d2d914560f8c73cf5e6b80b8e0f47f498d64"
LIBDDOC="73f2761d859b0364b0b5f77e6316b87ef7052d4f"
LIBDPARSE="222548fe610ee33dc60a87c9c1322aedd487dcdb"
GITHUB_URI="https://codeload.github.com"
SRC_URI="
	${GITHUB_URI}/dlang-community/${PN}/tar.gz/v${PV} -> ${P}.tar.gz
	${GITHUB_URI}/economicmodeling/containers/tar.gz/${CONTAINERS} -> containers-${CONTAINERS}.tar.gz
	${GITHUB_URI}/dlang-community/dsymbol/tar.gz/${DSYMBOL} -> dsymbol-${DSYMBOL}.tar.gz
	${GITHUB_URI}/burner/inifiled/tar.gz/${INIFILED} -> inifiled-${INIFILED}.tar.gz
	${GITHUB_URI}/economicmodeling/libddoc/tar.gz/${LIBDDOC} -> libddoc-${LIBDDOC}.tar.gz
	${GITHUB_URI}/dlang-community/libdparse/tar.gz/${LIBDPARSE} -> libdparse-${LIBDPARSE}.tar.gz
	"
S="${WORKDIR}/D-Scanner-${PV}"

DLANG_VERSION_RANGE="2.072-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../containers-${CONTAINERS}            containers                       || die
	mv -T ../dsymbol-${DSYMBOL}                  dsymbol                          || die
	mv -T ../inifiled-${INIFILED}                inifiled                         || die
	mv -T ../libddoc-${LIBDDOC}                  libddoc                          || die
	mv -T ../libdparse-${LIBDPARSE}              libdparse                        || die
	# Stop makefile from executing git to write an unused githash.txt
	touch githash githash.txt || die "Could not generate githash"
	# Apply patches
	dlang_src_prepare
}

compile_dscanner() {
	local paths="containers/src dsymbol/src inifiled/source/ libddoc/src/ libdparse/src/ src/"
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
