# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="Ancilliary tools for the D programming language compiler"
HOMEPAGE="http://dlang.org/"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 x86"
TOOLS="rdmd ddemangle detab dman dustmite"
IUSE="+rdmd +ddemangle detab +dman dustmite"
REQUIRED_USE="|| ( ${TOOLS} )"

inherit versionator

DLANG_SLOT="$(get_version_component_range 1-2)"
GITHUB_URI="https://codeload.github.com/D-Programming-Language"
SRC_URI="
	${GITHUB_URI}/tools/tar.gz/v${PV} -> dlang-tools-${PV}.tar.gz
	dman? (
		${GITHUB_URI}/phobos/tar.gz/v${PV} -> phobos-${PV}.tar.gz
		${GITHUB_URI}/dlang.org/tar.gz/v${PV} -> dlang.org-${PV}.tar.gz
	)"
DEPEND="dman? ( =dev-lang/dmd-${PV}*:${DLANG_SLOT} )"

DLANG_VERSION_RANGE="${DLANG_SLOT}-"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang

S="${WORKDIR}"

src_prepare() {
	mv "tools-${PV}" "tools" || die "Could not rename tools-${PV} to tools"
	if use dman; then
		mv "phobos-${PV}" "phobos" || die "Could not rename phobos-${PV} to phobos"
		mv "dlang.org-${PV}" "dlang.org" || die "Could not rename dlang.org-${PV} to dlang.org"
		echo "${PV}" > VERSION || die "Could not write VERSION file"
	fi
}

d_src_compile() {
	mkdir -p "tools/generated/${CHOST}" || die "Could not create output directory"
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			if [[ "${tool}" == dman ]]; then
				emake -C "dlang.org" -f posix.mak LATEST="${PV}" DMD="${DMD}" html
				emake -C "phobos" -f posix.mak \
					DOC_OUTPUT_DIR="../dlang.org/web/phobos" SONAME="" \
					VERSION="../VERSION" \
					DMD="${ROOT}opt/dmd-${DLANG_SLOT}/bin/dmd" html
			fi
			DFLAGS="${DMDFLAGS}" emake -C "tools" -f posix.mak DMD="${DMD}" ROOT="generated/${CHOST}" "${tool}"
		fi
	done
}

d_src_install() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			dobin "tools/generated/${CHOST}/${tool}"
		fi
	done
}