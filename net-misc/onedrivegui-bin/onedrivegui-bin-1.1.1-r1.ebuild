# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

M_PN=OneDriveGUI

DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"

inherit desktop xdg-utils
SRC_URI="
    https://github.com/bpozdena/${M_PN}/releases/download/v${PV}/${M_PN}-${PV}_fix150-x86_64.AppImage -> ${PN}-${PV}.AppImage
    https://github.com/bpozdena/${M_PN}/blob/v${PV}/src/resources/images/OneDriveGUI.png -> OneDriveGUI-${PV}.png
"
S="${WORKDIR}"

RDEPEND="
    >=net-misc/onedrive-2.5
    sys-fs/fuse:0
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
RESTRICT="strip"

src_install() {
    #Install binary and alias command
    newbin "${DISTDIR}/${PN}-${PV}.AppImage" OneDriveGUI

    #Icon and Desktop File
    newicon "${DISTDIR}/OneDriveGUI-${PV}.png" OneDriveGUI.png
    domenu "${FILESDIR}/OneDriveGUI.desktop"
}

pkg_postinst() {
    xdg_desktop_database_update
}
