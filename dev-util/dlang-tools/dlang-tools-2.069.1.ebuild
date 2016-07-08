# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

DESCRIPTION="Ancilliary tools for the D programming language compiler"
HOMEPAGE="http://dlang.org/"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 x86"
TOOLS="rdmd ddemangle detab dustmite"
IUSE="+rdmd +ddemangle detab dustmite"
REQUIRED_USE="|| ( ${TOOLS} )"

inherit versionator

DLANG_SLOT="$(get_version_component_range 1-2)"
RESTRICT="mirror"
GITHUB_URI="https://github.com/D-Programming-Language/tools/archive"
BETA="$(echo $(get_version_component_range 4) | cut -c 5-)"
VERSION="$(get_version_component_range 1-3)"

if [[ -n "${BETA}" ]]; then
	VERSION="${VERSION}-b${BETA}"
fi
SRC_URI="${GITHUB_URI}/v${VERSION}.tar.gz -> dlang-tools-${VERSION}.tar.gz"

DLANG_VERSION_RANGE="${DLANG_SLOT}"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang

S="${WORKDIR}/tools-${VERSION}"

d_src_compile() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			emake -f posix.mak DMD="${DMD}" DFLAGS="${DMDFLAGS}" "${tool}"
		fi
	done
}

d_src_install() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			dobin generated/linux/*/"${tool}"
		fi
	done
}
