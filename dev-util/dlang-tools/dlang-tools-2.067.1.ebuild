# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Ancilliary tools for the D programming language compiler"
HOMEPAGE="http://dlang.org/"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="amd64 x86"
TOOLS="rdmd ddemangle detab dustmite"
IUSE="+rdmd +ddemangle detab +dman dustmite"
REQUIRED_USE="|| ( ${TOOLS} dman )"

inherit versionator

DLANG_SLOT="$(get_version_component_range 1-2)"
RESTRICT="mirror"
GITHUB_URI="https://codeload.github.com/D-Programming-Language"
SRC_URI="
	${GITHUB_URI}/tools/tar.gz/v${PV} -> dlang-tools-${PV}.tar.gz
	dman? (
		${GITHUB_URI}/dmd/tar.gz/v${PV} -> dmd-${PV}.tar.gz
		${GITHUB_URI}/druntime/tar.gz/v${PV} -> druntime-${PV}.tar.gz
		${GITHUB_URI}/phobos/tar.gz/v${PV} -> phobos-${PV}.tar.gz
		${GITHUB_URI}/dlang.org/tar.gz/v${PV} -> dlang.org-${PV}.tar.gz
	)"

DLANG_VERSION_RANGE="${DLANG_SLOT}"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang

S="${WORKDIR}"

src_prepare() {
	mv "tools-${PV}" "tools" || die "Could not rename tools-${PV} to tools"
	if use dman; then
		mv "dlang.org-${PV}" "dlang.org" || die "Could not rename dlang.org-${PV} to dlang.org"
		mv "dmd-${PV}" "dmd" || die "Could not rename dmd-${PV} to dmd"
		touch dmd/.cloned || die "Could not touch 'dmd/.cloned'"
		mv "druntime-${PV}" "druntime" || die "Could not rename druntime-${PV} to druntime"
		mv "phobos-${PV}" "phobos" || die "Could not rename phobos-${PV} to phobos"
	fi
}

d_src_compile() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			emake -C "tools" -f posix.mak DMD="${DMD}" DFLAGS="${DMDFLAGS}" "${tool}"
		fi
	done
	if use dman; then
		# This builds chmgen with the system D compiler (and also a vanilla DMD
		# as a dependency from the make file.) A dummy PHOBOS_DIR is set to make
		# the build process use the system Phobos instead.
		emake -C "dlang.org" -f posix.mak RELEASE=1 LATEST="${PV}" TARGET_CPU=X86 DMD="${DMD}" PHOBOS_DIR="." chmgen
		# Next we populate the druntime/import directory as required by the HTML
		# generation process.
		emake -C "druntime" -f posix.mak DMD="${DMD}" import copy
		# Then we generate Phobos HTML documentation that can be parsed by
		# chmgen when building dman.
		emake -C "phobos" -f posix.mak DOC_OUTPUT_DIR="../dlang.org/web/phobos" DMD="${DMD}" html
		# The last step creates the actual executable.
		emake -C "tools" -f posix.mak RELEASE=1 LATEST="${PV}" DMD="${DMD}" DFLAGS="${DMDFLAGS} -J../dlang.org" dman
	fi
}

d_src_install() {
	for tool in ${TOOLS} dman; do
		if use "${tool}"; then
			dobin tools/generated/linux/*/"${tool}"
		fi
	done
}
