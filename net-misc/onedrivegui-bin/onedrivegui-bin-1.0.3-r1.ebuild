# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

M_PN=OneDriveGUI

inherit desktop xdg-utils
SRC_URI="
    https://github.com/bpozdena/OneDriveGUI/releases/download/v1.0.3/OneDriveGUI-1.0.3_fix150-x86_64.AppImage -> ${PN}-${PV}.AppImage
    https://github.com/bpozdena/OneDriveGUI/blob/v${PV}/src/resources/images/OneDriveGUI.ico -> OneDriveGUI-${PV}.ico
"
DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"

RDEPEND="
    <=net-misc/onedrive-2.5.3
    sys-fs/fuse:0
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip"

S="${WORKDIR}"

src_install() {
	#Install binary and alias command
	insinto /opt/bin/ && newins "${DISTDIR}/${PN}-${PV}.AppImage" "OneDriveGUI"
    fperms +x /opt/bin/OneDriveGUI

	#Icon and Desktop File
	newicon "${DISTDIR}/OneDriveGUI-${PV}.ico" -> "OneDriveGUI.ico"
	domenu "${FILESDIR}/OneDriveGUI.desktop"
}

pkg_postinst() {
        xdg_desktop_database_update
}
