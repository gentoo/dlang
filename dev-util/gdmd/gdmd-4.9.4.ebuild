# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="http://www.gdcproject.org/"
LICENSE="GPL-3+"

SLOT="${PV}"
KEYWORDS="amd64 arm ~arm64 ia64 ~m68k ppc ppc64 ~s390 ~sh x86 ~amd64-fbsd ~x86-fbsd"
DEPEND="=sys-devel/gcc-${PV}*[d]"
RDEPEND="${DEPEND}"
FRONTEND="2.068.2"
SRC_URI="https://codeload.github.com/D-Programming-GDC/GDMD/tar.gz/v${FRONTEND} -> gdmd-${FRONTEND}.tar.gz"
S="${WORKDIR}/GDMD-${FRONTEND}"

DLANG_PACKAGE_TYPE="single"
DLANG_USE_COMPILER="gdc-4.9.4"

inherit dlang

d_src_compile() {
	local versions="GCC_49_Plus"
	dlang_compile_bin "gdmd" "src/main.d" "src/gdmd/*.d"
}

d_src_install() {
	local binPath="usr/${CHOST}/gcc-bin/${PV}"
	exeinto "${binPath}"
	newexe gdmd "${CHOST}-gdmd"
	ln -f "${D}${binPath}/${CHOST}-gdmd" "${D}${binPath}/gdmd" || die "Could not create 'gdmd' hardlink"
}
