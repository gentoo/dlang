# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Free Client for OneDrive on Linux"
HOMEPAGE="https://github.com/skilion/onedrive"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64 ~x86"
RDEPEND="
	>=dev-db/sqlite-3.7.15:3
	net-misc/curl
	libnotify? ( x11-libs/libnotify )
"
DEPEND="${RDEPEND}"
SRC_URI="https://codeload.github.com/abraunegg/onedrive/tar.gz/v${PV} -> ${P}.tar.gz"
DLANG_VERSION_RANGE="2.079-"
DLANG_PACKAGE_TYPE="single"
IUSE="libnotify"

inherit dlang systemd

src_prepare() {
	mkdir .git
	touch .git/HEAD .git/index
	echo "v${PV}" > version
	default_src_prepare
}

d_src_compile() {
	if use libnotify; then
		local notifications="NOTIFICATIONS=1"
		local dflags_notifications="-version=NoPragma -version=NoGdk -version=Notifications -L-lgmodule-2.0 -L-lglib-2.0 -L-lnotify"
	fi
	emake ${notifications} PREFIX="${ESYSROOT}/usr" DC="${DMD}" DFLAGS="${DCFLAGS} -J. -L-lcurl -L-lsqlite3 ${dflags_notifications} -ofonedrive"
}

src_test() {
	: # Tests require an API authorization.
}

src_install() {
	# program binary
	dobin onedrive
	# log directory
	keepdir /var/log/onedrive
	fperms 775 /var/log/onedrive
	fowners root:users /var/log/onedrive
	# init script
	dobin init.d/onedrive_service.sh
	newinitd init.d/onedrive.init onedrive
	# logrotate script
	insinto /etc/logrotate.d
	newins logrotate/onedrive.logrotate onedrive
	# systemd units
	systemd_douserunit onedrive.service
	systemd_dounit onedrive@.service
	# man page
	doman onedrive.1
}

pkg_postinst() {
	elog "OneDrive Free Client needs to be authorized to access your data before the"
	elog "first use. To do so, run onedrive in a terminal for the user in question and"
	elog "follow the steps on screen."
	elog
	ewarn "The 'skilion' version contains a significant number of defect's in how the"
	ewarn "local sync state is managed. When upgrading from the 'skilion' version to this"
	ewarn "version, it is advisable to stop any service / onedrive process from running"
	ewarn "and then remove your configuration directory (~/.config/onedrive/)."
}
