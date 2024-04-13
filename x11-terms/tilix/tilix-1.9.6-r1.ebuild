# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A tiling terminal emulator for Linux using GTK+ 3"
HOMEPAGE="https://gnunn1.github.io/tilix-web/"
LICENSE="MPL-2.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"

GITHUB_URI="https://codeload.github.com/gnunn1"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/${PV} -> ${PN}-${PV}.tar.gz"
IUSE="test"
RESTRICT="!test? ( test )"

DLANG_COMPAT=( ldc2-1_{35..36} )

inherit dlang-single gnome2-utils meson optfeature

REQUIRED_USE=${DLANG_REQUIRED_USE}
RDEPEND="
	${DLANG_DEPS}
	>=sys-devel/gettext-0.19.8.1
	$(dlang_gen_cond_dep '
		>=dev-libs/gtkd-3.10.0-r2:3[vte,${DLANG_USEDEP}]
	')
	sys-libs/libunwind
	gnome-base/gsettings-desktop-schemas
"
DEPEND=${RDEPEND}
BDEPEND="
	${DLANG_DEPS}
	app-text/po4a
	dev-libs/appstream
	test? ( dev-util/desktop-file-utils )
"

src_configure() {
	DFLAGS="${DCFLAGS}" meson_src_configure -Dd_link_args="${DCFLAGS} ${DLANG_LDFLAGS}"
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
