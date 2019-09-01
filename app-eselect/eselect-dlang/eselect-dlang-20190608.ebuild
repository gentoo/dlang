# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Eselect module for management of multiple D versions"
HOMEPAGE="https://github.com/gentoo-dlang"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 x86"
IUSE=""

RDEPEND="app-admin/eselect"
DEPEND=""

S="${FILESDIR}"

src_install() {
	insinto /usr/share/eselect/modules
	newins dlang.eselect-${PV} dlang.eselect
	dodir /usr/include/dlang
}
