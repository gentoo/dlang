# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.4"
#UCLIBC_VER="1.0"

inherit toolchain git-r3 eapi7-ver

KEYWORDS="amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~ppc-macos"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

IUSE="d d-bootstrap"
REQUIRED_USE="${REQUIRED_USE} d-bootstrap? ( d )"
PDEPEND="${PDEPEND} d? ( ~dev-util/gdmd-${PV} )"
EGIT_REPO_URI="https://github.com/D-Programming-GDC/gdc-archived.git"
EGIT_CHECKOUT_DIR="${WORKDIR}/gdc-`ver_cut 1`"

src_unpack() {
	toolchain_src_unpack
	if use d-bootstrap ; then
		EGIT_BRANCH="gdc-`ver_cut 1`-stable"
	else
		EGIT_BRANCH="gdc-`ver_cut 1`"
		EGIT_COMMIT="95a735b5441d7d72578c0ceeb95aa753bfcd928b"
	fi
	git-r3_src_unpack
}

src_prepare() {
	toolchain_src_prepare

	if use d ; then
		# Get GDC sources into the tree.
		cd "${EGIT_CHECKOUT_DIR}" || die "Changing into GDC directory failed."
		use d-bootstrap && use pgo && epatch "${FILESDIR}"/gdc-`ver_cut 1`-pgo.patch
		./setup-gcc.sh ../gcc-${GCC_PV} || die "Could not setup GDC."
	fi
}
