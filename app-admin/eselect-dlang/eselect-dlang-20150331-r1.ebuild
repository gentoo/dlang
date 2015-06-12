# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="Eselect module for management of multiple D versions"
HOMEPAGE="https://github.com/gentoo-dlang"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86 ~ppc64"
IUSE=""

RDEPEND="app-admin/eselect"
DEPEND=""

S="${FILESDIR}"

src_install() {
	insinto /usr/share/eselect/modules
	newins dlang.eselect-${PV} dlang.eselect
}
