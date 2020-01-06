# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Free Client for OneDrive on Linux"
HOMEPAGE="https://github.com/abraunegg/onedrive"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="amd64 x86"
RDEPEND="
	>=dev-db/sqlite-3.7.15:3
	net-misc/curl
	libnotify? ( x11-libs/libnotify )
"
DEPEND="
	${RDEPEND}
	virtual/pkgconfig
"
SRC_URI="https://codeload.github.com/abraunegg/onedrive/tar.gz/v${PV} -> ${P}.tar.gz"
DLANG_VERSION_RANGE="2.082-"
DLANG_PACKAGE_TYPE="single"
IUSE="debug libnotify"

inherit dlang systemd bash-completion-r1

src_prepare() {
	mkdir .git
	touch .git/HEAD .git/index
	echo "v${PV}" > version
	default_src_prepare
}

d_src_configure() {
	# LDC is supported without wrapper
	if [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		export DC=${DC}
		export DCFLAGS=${DCFLAGS}
	else
		export DC=${DMD}
		export DCFLAGS=${DMDFLAGS}
	fi
	econf --disable-version-check --enable-completions $(use_enable debug) $(use_enable libnotify notifications) \
		--with-zsh-completion-dir=/usr/share/zsh/site-functions --with-bash-completion-dir="$(get_bashcompdir)" \
		--with-systemdsystemunitdir="$(systemd_get_systemunitdir)" \
		--with-systemduserunitdir="$(systemd_get_userunitdir)"
}

src_install() {
	emake DESTDIR="${D}" docdir=/usr/share/doc/${PF} install
	# log directory
	keepdir /var/log/onedrive
	fperms 775 /var/log/onedrive
	fowners root:users /var/log/onedrive
	# init script
	dobin contrib/init.d/onedrive_service.sh
	newinitd contrib/init.d/onedrive.init onedrive
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
