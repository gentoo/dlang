# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A tiling terminal emulator for Linux using GTK+ 3"
HOMEPAGE="https://gnunn1.github.io/tilix-web/"
LICENSE="MPL-2.0"

SLOT="0"
KEYWORDS="amd64 x86"

DLANG_VERSION_RANGE="2.099-2.105"
DLANG_PACKAGE_TYPE="single"
# Using dmd and gdc results in linking errors currently.
# Upstream only tests with ldc2 as well.
DLANG_COMPILER_DISABLED_BACKENDS=(dmd gdc)

inherit gnome2-utils meson optfeature dlang

GITHUB_URI="https://codeload.github.com/gnunn1"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/${PV} -> ${PN}-${PV}.tar.gz"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=sys-devel/gettext-0.19.8.1
	>=dev-libs/gtkd-3.10.0-r1:3[vte,${DLANG_COMPILER_USE}]
	sys-libs/libunwind
	gnome-base/gsettings-desktop-schemas
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	app-text/po4a
	dev-libs/appstream
	test? ( dev-util/desktop-file-utils )
"

d_src_configure() {
	DFLAGS="${DCFLAGS}" meson_src_configure
}

d_src_compile() {
	meson_src_compile
}

d_src_test() {
	meson_src_test
}

d_src_install() {
	meson_src_install
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
	gnome2_schemas_update

	optfeature "Nautilus integration" "dev-python/nautilus-python"
	optfeature "Password support" "app-crypt/libsecret gnome-base/gnome-keyring"
}

pkg_postrm() {
	gnome2_schemas_update
	xdg_desktop_database_update
	xdg_icon_cache_update
}
