# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

M_PN=OneDriveGUI

inherit desktop
SRC_URI="https://github.com/bpozdena/OneDriveGUI/archive/refs/tags/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz"
DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"

RDEPEND="<=net-misc/onedrive-2.5.3
	dev-python/requests
	dev-python/pyside6[gui(+),webengine(+),widgets(+)]
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${M_PN}-${PV}"

src_install() {
	#Install binary and alias command
	insinto /opt/OneDriveGUI/ && doins -r "${S}/src/resources" && doins -r "${S}/src/ui" && doins -r "${S}/src/OneDriveGUI.py"
	insinto /opt/bin/ && doins "${FILESDIR}/OneDriveGUI"
	fperms +x /opt/OneDriveGUI/OneDriveGUI.py /opt/bin/OneDriveGUI

	#Icon and Desktop File
	doicon "${S}/src/resources/images/OneDriveGUI.ico"
	domenu "${FILESDIR}/OneDriveGUI.desktop"
}
