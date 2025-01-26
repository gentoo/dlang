# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

M_PN=OneDriveGUI

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=(python3_{9..13})

inherit desktop distutils-r1
if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/bpozdena/${M_PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/bpozdena/${M_PN}/archive/refs/tags/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz"
	KEYWORDS="~amd64"
    S="${WORKDIR}/${M_PN}-${PV}"
fi

DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"

RDEPEND="<net-misc/onedrive-2.5
	dev-python/requests
	dev-python/pyside6[gui(+),webengine(+),widgets(+)]
"

LICENSE="GPL-3"
SLOT="0"

src_prepare() {
    cp "${FILESDIR}/setup-onedrivegui.py" "${S}/setup.py" || die
    cp "${FILESDIR}/setup-onedrivegui.cfg" "${S}/setup.cfg" || die
    cp "${FILESDIR}/OneDriveGUI.desktop" "${S}/src/OneDriveGUI.desktop" || die

    if [[ ${PV} == "9999" ]]; then
		#fix python package version
		sed -i "s/version = _VERSION/version = 9999/g" "${S}/setup.cfg" || die
	else
		#fix python package version
		sed -i "s/version = _VERSION/version = ${PV}/g" "${S}/setup.cfg" || die
	fi

    default
}