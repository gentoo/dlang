# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Ancilliary tools for the D programming language compiler"
HOMEPAGE="http://dlang.org/"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"
TOOLS="ddemangle detab dustmite rdmd"
IUSE="+ddemangle detab dustmite +rdmd"

DLANG_SLOT="$(ver_cut 1-2)"
RESTRICT="mirror"

BETA="$(ver_cut 4)"
VERSION="$(ver_cut 1-3)"

if [[ -n "${BETA}" ]]; then
	# We want to convert a Gentoo version string into an upstream one: 2.097.0_rc1 -> 2.097.0-rc.1
	VERSION="$(ver_rs 3 "-" 4 ".")"
fi
SRC_URI="https://codeload.github.com/dlang/tools/tar.gz/v${VERSION} -> dlang-tools-${VERSION}.tar.gz"

DLANG_COMPAT=( dmd-2_{106..107} gdc-12 ldc2-1_{35..36} )

inherit desktop dlang-single xdg-utils

REQUIRED_USE="|| ( ${TOOLS[@]} ) ${DLANG_REQUIRED_USE}"
DEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}

S="${WORKDIR}/tools-${VERSION}"

src_compile() {
	use ddemangle && dlang_compile_bin ddemangle ddemangle.d
	use detab     && dlang_compile_bin detab     detab.d
	use dustmite  && dlang_compile_bin dustmite  DustMite/dustmite.d DustMite/splitter.d DustMite/polyhash.d
	use rdmd      && dlang_compile_bin rdmd      rdmd.d
}

src_install() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			dobin "${tool}"
		fi
	done

	# file icons
	for size in 16 22 24 32 48 256; do
		newicon --size "${size}" --context mimetypes "${FILESDIR}/icons/${size}/dmd-source.png" text-x-dsrc.png
	done
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
