# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A tiling terminal emulator for Linux using GTK+ 3"
HOMEPAGE="https://gnunn1.github.io/tilix-web/"
LICENSE="MPL-2.0"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+crypt"

DLANG_VERSION_RANGE="2.075-2.086"
DLANG_PACKAGE_TYPE="single"

inherit dlang

GITHUB_URI="https://codeload.github.com/gnunn1"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/${PV} -> ${PN}-${PV}.tar.gz"

RDEPEND="
	>=sys-devel/gettext-0.19.8.1
	>=dev-libs/gtkd-3.8.5:3[vte,${DLANG_COMPILER_USE}]
	x11-libs/vte:2.91[crypt?]"
DEPEND="
	sys-devel/automake:1.16
	>=sys-devel/autoconf-2.69
	app-text/po4a
	${RDEPEND}"

src_prepare() {
	eapply_user
	./autogen.sh
}

d_src_configure() {
	export GTKD_CFLAGS="-I/usr/include/dlang/gtkd-3"
	export GTKD_LIBS="-L-ldl -L-lvted-3 -L-lgtkd-3"
	default_src_configure
}

d_src_install() {
	default_src_install
	# Silence "Please fix the ebuild not to install compressed files" QA warnings
	gzip -d "${D}"/usr/share/man/man1/tilix.1.gz "${D}"/usr/share/man/*/man1/tilix.1.gz
}
