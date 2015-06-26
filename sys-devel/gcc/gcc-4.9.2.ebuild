# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.9.2.ebuild,v 1.20 2015/06/14 17:58:37 mgorny Exp $

EAPI="4"

EGIT_REPO_URI="git://github.com/D-Programming-GDC/GDC.git"
EGIT_BRANCH="gdc-4.9"
EGIT_COMMIT="v2.066.1_gcc4.9"
EGIT_CHECKOUT_DIR="${WORKDIR}/dev"

inherit git-r3

IUSE="d"

# Original GCC code starts here
PATCH_VER="1.5"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.6.2"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 mips ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 mips ppc ppc64"
SSP_STABLE="amd64 x86 mips ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc need to be >= 0.9.33
SSP_UCLIBC_STABLE="x86 amd64 mips ppc ppc64 arm"
#end Hardened stuff

inherit eutils toolchain

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	>=${CATEGORY}/binutils-2.20"
PDEPEND="d? ( =dev-util/gdmd-${PV}* )"

GCC_FILESDIR=${PORTDIR}/sys-devel/gcc/files

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

src_prepare() {
	if has_version '<sys-libs/glibc-2.12' ; then
		ewarn "Your host glibc is too old; disabling automatic fortify."
		ewarn "Please rebuild gcc after upgrading to >=glibc-2.12 #362315"
		EPATCH_EXCLUDE+=" 10_all_default-fortify-source.patch"
	fi

	toolchain_src_prepare

	use vanilla && return 0
	#Use -r1 for newer piepatchet that use DRIVER_SELF_SPECS for the hardened specs.
	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env-r1.patch

	if use d ; then
		# Get GDC sources into the tree.
		git-r3_src_unpack
		cd ../dev || die "Changing into Git checkout directory failed."
		./setup-gcc.sh ../gcc-${GCC_PV} || die "Could not setup GDC."
	fi
}
