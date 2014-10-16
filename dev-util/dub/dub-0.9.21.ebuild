# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="Package and build management system for the D programming language"
HOMEPAGE="http://code.dlang.org/"
LICENSE="MIT"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE="debug"

GITHUB_URI="https://codeload.github.com/D-Programming-Language"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/v${PV} -> ${PN}-${PV}.tar.gz"

DLANG_VERSION_RANGE="2.063-"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang

DEPEND="net-misc/curl"
RDEPEND="${DEPEND}"

d_src_compile() {
	local imports=source versions=DubUseCurl libs=curl
	dlang_compile_bin bin/dub $(<build-files.txt)
}

d_src_install() {
	dobin bin/dub
	dodoc README.md
}