# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Package and build management system for the D programming language"
HOMEPAGE="http://code.dlang.org/"
LICENSE="MIT"

SLOT="0"
KEYWORDS="amd64 x86 ~arm"
IUSE="debug"

GITHUB_URI="https://codeload.github.com/D-Programming-Language"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/v${PV} -> ${PN}-${PV}.tar.gz"

DLANG_VERSION_RANGE="2.066-"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang

DEPEND="net-misc/curl"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}/${P}-gdc-dmd-pathfix.patch"
}

d_src_compile() {
	local imports=source versions=DubUseCurl libs="curl z"
	dlang_compile_bin bin/dub $(<build-files.txt)
}

d_src_install() {
	dobin bin/dub
	dodoc README.md
}
