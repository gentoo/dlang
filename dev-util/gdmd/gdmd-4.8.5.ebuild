# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="http://www.gdcproject.org/"
LICENSE="GPL-3+"

SLOT="${PV}"
KEYWORDS="amd64 arm ia64 ppc ppc64 x86 ~amd64-fbsd"
DEPEND="=sys-devel/gcc-${PV}*[d]"
RDEPEND=""

EGIT_REPO_URI="git://github.com/D-Programming-GDC/GDMD.git"
EGIT_COMMIT="89d9b01398a38d4a19376485d22ee311932a4525"

inherit git-2 eutils

src_prepare() {
	epatch "${FILESDIR}"/no-dmd-conf.patch
}

src_install() {
	local binPath="usr/${CHOST}/gcc-bin/${PV}"
	exeinto "${binPath}"
	newexe dmd-script "${CHOST}-gdmd"
	ln -f "${D}${binPath}/${CHOST}-gdmd" "${D}${binPath}/gdmd" || die "Could not create 'gdmd' hardlink"
}
