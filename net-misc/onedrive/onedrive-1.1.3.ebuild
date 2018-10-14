# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Free Client for OneDrive on Linux"
HOMEPAGE="https://github.com/skilion/onedrive"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64 ~x86"
RDEPEND="
	dev-db/sqlite:3
"
DEPEND="${RDEPEND}"

VERSION="$(ver_cut 1-3)"
SRC_URI="https://codeload.github.com/skilion/onedrive/tar.gz/v${VERSION} -> onedrive-${VERSION}.tar.gz"

DLANG_VERSION_RANGE="2.072-"
DLANG_PACKAGE_TYPE="single"

inherit dlang systemd

S="${WORKDIR}/onedrive-${VERSION}"

src_prepare() {
	mkdir .git
	touch .git/HEAD .git/index
	echo "v${VERSION}" > version
	default_src_prepare
}

d_src_compile() {
	emake PREFIX="${ESYSROOT}/usr" DC="${DMD}" DFLAGS="${DCFLAGS} -J. -L-lcurl -L-lsqlite3 -ofonedrive"
}

src_test() {
	: # Tests require an API authorization.
}

src_install() {
	dobin onedrive
	systemd_douserunit onedrive.service
}

pkg_postinst() {
	elog "OneDrive Free Client needs to be authorized with Microsoft before the first use."
	elog "To do so, run onedrive in a terminal for the user in question and follow the steps on screen."
}
