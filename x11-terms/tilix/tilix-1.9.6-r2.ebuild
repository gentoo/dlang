# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( dmd-2_10{6..9} gdc-1{3,4} ldc2-1_{35..39} )
inherit dlang-single gnome2-utils meson optfeature

DESCRIPTION="A tiling terminal emulator for Linux using GTK+ 3"
HOMEPAGE="https://gnunn1.github.io/tilix-web/"

GITHUB_URI="https://codeload.github.com/gnunn1"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/${PV} -> ${PN}-${PV}.tar.gz"
LICENSE="MPL-2.0"

PATCHES=(
	"${FILESDIR}/fix-dmd-and-gdc-build-pr-2219.patch"
	"${FILESDIR}/remove-libunwind-dep-pr-2220.patch"
)

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="test"
RESTRICT="!test? ( test )"

# Older gcc ICEs due to https://gcc.gnu.org/PR113125
MY_DLANG_DEPS="${DLANG_DEPS}
	$(dlang_gen_cond_dep '
		>=sys-devel/gcc-13.3:13
	' gdc-13)
"

REQUIRED_USE=${DLANG_REQUIRED_USE}
RDEPEND="
	${MY_DLANG_DEPS}
	>=sys-devel/gettext-0.19.8.1
	$(dlang_gen_cond_dep '
		>=dev-libs/gtkd-3.10.0-r2:3[vte,${DLANG_USEDEP}]
	')
	gnome-base/gsettings-desktop-schemas
"
DEPEND=${RDEPEND}
BDEPEND="
	${MY_DLANG_DEPS}
	app-text/po4a
	dev-libs/appstream
	test? ( dev-util/desktop-file-utils )
"

src_configure() {
	# meson is very strict in how he expects the linker flags. It
	# modifies our flags from:
	# -Lz -Lpack-relative-relocs
	# to:
	# -Lz -L=-Lpack-relative-relocs
	#
	# Note that specyfing -L=z -L=pack-relative-relocs is still not enough
	# as meson modifies the second argument again.
	#
	# This only works so long as the eclass doesn't add any extra flags
	# for dmd or ldc (it does for gdc).
	local largs
	[[ ${EDC} != gdc* ]] && largs="${LDFLAGS}" || largs="${DLANG_LDFLAGS}"

	DFLAGS="${DCFLAGS}" meson_src_configure -Dd_link_args="${largs}"
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
	gnome2_schemas_update

	optfeature "Nautilus integration" "dev-python/nautilus-python"
	optfeature "Password support" "app-crypt/libsecret"
}

pkg_postrm() {
	gnome2_schemas_update
	xdg_desktop_database_update
	xdg_icon_cache_update
}
