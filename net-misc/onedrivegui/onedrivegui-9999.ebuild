# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

M_PN=OneDriveGUI

inherit desktop git-r3
EGIT_REPO_URI="https://github.com/bpozdena/OneDriveGUI.git"
DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"

DEPEND="net-misc/onedrive
	dev-python/requests
	dev-python/pyside6[gui(+),webengine(+),widgets(+)]
"

LICENSE="GPL-3"
SLOT="0"

src_install() {
	#Install binary and alias command
	insinto /opt/OneDriveGUI/ && doins -r "${S}/src/resources" && doins -r "${S}/src/ui" && doins -r "${S}/src/OneDriveGUI.py"
	insinto /opt/bin/ && doins "${FILESDIR}/OneDriveGUI"
	fperms +x /opt/OneDriveGUI/OneDriveGUI.py /opt/bin/OneDriveGUI

	#Icon and Desktop File
	doicon "${S}/src/resources/images/OneDriveGUI.ico"
	domenu "${FILESDIR}/OneDriveGUI.desktop"
}
