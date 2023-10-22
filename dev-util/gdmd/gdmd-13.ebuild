# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="https://www.gdcproject.org/"
LICENSE="GPL-3+"

SLOT="${PV}"
KEYWORDS="~alpha amd64 arm arm64 ~ia64 ~loong ~m68k ~mips ~ppc ppc64 ~riscv ~s390 x86"
RDEPEND="sys-devel/gcc:${PV}[d]"
RELEASE="0.1.0"
SRC_URI="https://codeload.github.com/D-Programming-GDC/gdmd/tar.gz/script-${RELEASE} -> gdmd-${RELEASE}.tar.gz"
PATCHES="${FILESDIR}/${PN}-no-dmd-conf.patch"
S="${WORKDIR}/gdmd-script-${RELEASE}"

src_compile() {
	:
}

src_install() {
	local binPath="usr/${CHOST}/gcc-bin/${PV}"
	exeinto "${binPath}"
	newexe dmd-script "${CHOST}-gdmd"
	ln -f "${D}/${binPath}/${CHOST}-gdmd" "${D}/${binPath}/gdmd" || die "Could not create 'gdmd' hardlink"
}
