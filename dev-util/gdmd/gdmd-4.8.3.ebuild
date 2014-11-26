# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="http://www.gdcproject.org/"
LICENSE="GPL-3+"

SLOT="${PV}"
KEYWORDS="amd64 arm ~ia64 ppc ppc64 x86 ~amd64-fbsd"
DEPEND="=sys-devel/gcc-${PV}*[d]"
RDEPEND=""

EGIT_REPO_URI="git://github.com/D-Programming-GDC/GDMD.git"
EGIT_COMMIT="37ca1c1f96632decb3a9f766bd25a430ecf770c8"

inherit git-2

src_install() {
	local binPath="/usr/${CHOST}/gcc-bin/${PV}"
	exeinto "${binPath}"
	newexe dmd-script "${CHOST}-gdmd"
	dohard "${binPath}/${CHOST}-gdmd" "${binPath}/gdmd"
}
