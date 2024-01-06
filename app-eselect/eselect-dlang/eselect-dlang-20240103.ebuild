# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Eselect module for management of multiple D versions"
HOMEPAGE="https://github.com/gentoo/dlang"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="app-admin/eselect"

S="${FILESDIR}"

src_install() {
	insinto /usr/share/eselect/modules
	newins dlang.eselect-${PV} dlang.eselect
	keepdir /usr/include/dlang
}
