# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.1"
UCLIBC_VER="1.0"

inherit toolchain

KEYWORDS="alpha amd64 ~arm ~arm64 ~hppa ia64 ~m68k ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

IUSE="d"
PDEPEND="${PDEPEND} d? ( ~dev-util/gdmd-${PV} )"
SRC_URI="${SRC_URI}
	https://codeload.github.com/D-Programming-GDC/GDC/tar.gz/v2.068.2_gcc6 -> gdc-2.068.2_gcc-6.tar.gz"

src_unpack() {
	toolchain_src_unpack

	use d && unpack gdc-2.068.2_gcc-6.tar.gz
}

src_prepare() {
	toolchain_src_prepare

	if use d ; then
		# Get GDC sources into the tree.
		cd ../GDC-2.068.2_gcc6 || die "Changing into GDC directory failed."
		use pgo && epatch "${FILESDIR}"/gdc-pgo.patch
		./setup-gcc.sh ../gcc-${GCC_PV} || die "Could not setup GDC."
	fi
}
