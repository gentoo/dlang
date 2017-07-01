# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="A tiling terminal emulator for Linux using GTK+ 3"
HOMEPAGE="https://gnunn1.github.io/tilix-web/"
LICENSE="MPL-2.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+crypt"

DLANG_VERSION_RANGE="2.070-"
DLANG_PACKAGE_TYPE="single"
PLOCALES="ak ar_MA bg cs de el en es fr he id it ja ko lt nl pl pt_BR pt_PT ru sv tr uk zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit gnome2 dlang l10n

GITHUB_URI="https://codeload.github.com/gnunn1"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/${PV} -> ${PN}-${PV}.tar.gz"

RDEPEND="
	>=sys-devel/gettext-0.19.7
	>=dev-libs/gtkd-3.5.0:3[vte,${DLANG_COMPILER_USE}]
	x11-libs/vte:2.91[crypt?]"
DEPEND="
	>=sys-devel/autoconf-2.69
	sys-devel/automake:1.15
	app-text/po4a
	${RDEPEND}"

src_prepare() {
	eapply_user
	l10n_find_plocales_changes "${S}/po" "" ".po"
	./autogen.sh
}

d_src_configure()
{
	export GTKD_CFLAGS="-I/usr/include/dlang/gtkd-3"
	export GTKD_LIBS="${DLANG_LINKER_FLAG}-ldl ${DLANG_LINKER_FLAG}-lvted-3 ${DLANG_LINKER_FLAG}-lgtkd-3"
	LINGUAS=`l10n_get_locales` default_src_configure
}
