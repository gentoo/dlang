# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Ancilliary tools for the D programming language compiler"
HOMEPAGE="http://dlang.org/"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 x86"
TOOLS="rdmd ddemangle detab dustmite"
IUSE="+rdmd +ddemangle detab dustmite"
REQUIRED_USE="|| ( ${TOOLS} )"

inherit eapi7-ver

DLANG_SLOT="$(ver_cut 1-2)"
RESTRICT="mirror"
GITHUB_URI="https://codeload.github.com/dlang"
SRC_URI="${GITHUB_URI}/tools/tar.gz/v${PV} -> dlang-tools-${PV}.tar.gz"

DLANG_VERSION_RANGE="${DLANG_SLOT}-"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang xdg-utils

S="${WORKDIR}"

d_src_compile() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			emake -C "tools-${PV}" -f posix.mak DMD="${DMD}" DFLAGS="${DMDFLAGS}" "${tool}"
		fi
	done
}

d_src_install() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			dobin tools-"${PV}"/generated/linux/*/"${tool}"
		fi
	done
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
