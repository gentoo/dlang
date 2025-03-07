# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

M_PN=OneDriveGUI

DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"

inherit desktop xdg-utils
SRC_URI="
	https://github.com/bpozdena/${M_PN}/releases/download/v${PV}/${M_PN}-${PV}_fix150-x86_64.AppImage -> ${P}.AppImage
	https://raw.githubusercontent.com/bpozdena/${M_PN}/refs/tags/v${PV}/src/resources/images/${M_PN}.png -> OneDriveGUI-${PV}.png
"
S="${WORKDIR}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"

RDEPEND="
	<net-misc/onedrive-2.5
	!net-misc/onedrivegui
	sys-fs/fuse:0
"

RESTRICT="strip test"

src_install() {
	#Install binary and alias command
	newbin "${DISTDIR}/${P}.AppImage" OneDriveGUI

	#Icon and Desktop File
	newicon "${DISTDIR}/OneDriveGUI-${PV}.png" OneDriveGUI.png
	domenu "${FILESDIR}/OneDriveGUI.desktop"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
