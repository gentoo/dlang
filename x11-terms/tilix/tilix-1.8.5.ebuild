# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="A tiling terminal emulator for Linux using GTK+ 3"
HOMEPAGE="https://gnunn1.github.io/tilix-web/"
LICENSE="MPL-2.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+crypt"

DLANG_VERSION_RANGE="2.074-"
DLANG_PACKAGE_TYPE="single"

inherit gnome2 dlang

GITHUB_URI="https://codeload.github.com/gnunn1"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/${PV} -> ${PN}-${PV}.tar.gz"

RDEPEND="
	>=sys-devel/gettext-0.19.8.1
	>=dev-libs/gtkd-3.8.3:3[vte,${DLANG_COMPILER_USE}]
	x11-libs/vte:2.91[crypt?]"
DEPEND="
	sys-devel/automake:1.15
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
	DC="${DMD}" default_src_configure
}
