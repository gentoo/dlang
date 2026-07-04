# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( dmd-2_{107..111} gdc-15 ldc2-1_{36..40} )
inherit dlang-single optfeature prefix shell-completion systemd xdg-utils

DESCRIPTION="Free Client for OneDrive on Linux"
HOMEPAGE="https://abraunegg.github.io/"
SRC_URI="https://codeload.github.com/abraunegg/onedrive/tar.gz/v${PV} -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
# no straight forward way to run unittests. Probably need to do DFLAGS=-unittest econf
IUSE="libnotify"
RESTRICT="test"

REQUIRED_USE=${DLANG_REQUIRED_USE}
RDEPEND="
	${DLANG_DEPS}
	>=dev-db/sqlite-3.7.15:3
	net-misc/curl
	sys-apps/dbus
	libnotify? ( x11-libs/libnotify )
"
DEPEND="${RDEPEND}"
BDEPEND="
	${DLANG_DEPS}
	virtual/pkgconfig
"

src_prepare() {
	hprefixify contrib/init.d/onedrive.init
	# Add EPREFIX to the system config path (/etc)
	hprefixify -w '/string systemConfigDirBase/' src/config.d
	default
}

src_configure() {
	myeconfargs=(
		$(use_enable libnotify notifications)
		--with-bash-completion-dir="$(get_bashcompdir)"
		--with-zsh-completion-dir="$(get_zshcompdir)"
		--with-fish-completion-dir="$(get_fishcompdir)"
		--with-systemdsystemunitdir="$(systemd_get_systemunitdir)"
		--with-systemduserunitdir="$(systemd_get_userunitdir)"
		--enable-completions
		--disable-version-check
		# Adds -g and -debug. There are only a few instructions guarded by debug
		--disable-debug
	)
	DCFLAGS="${DCFLAGS} ${DLANG_LDFLAGS}" econf "${myeconfargs[@]}"
}

src_install() {
	emake DESTDIR="${D}" docdir="${EPREFIX}"/usr/share/doc/${PF} install
	# log directory
	keepdir /var/log/onedrive
	fperms 775 /var/log/onedrive
	fowners root:users /var/log/onedrive
	# init script
	dobin contrib/init.d/onedrive_service.sh
	newinitd contrib/init.d/onedrive.init onedrive
}

pkg_postinst() {
	xdg_icon_cache_update
	elog "OneDrive Free Client needs to be authorized to access your data before the"
	elog "first use. To do so, run onedrive in a terminal for the user in question and"
	elog "follow the steps on screen."

	local old_ver minor_part="$(ver_cut 1-2)"
	for old_ver in ${REPLACING_VERSIONS}; do
		if ver_test "${old_ver}" -lt "${minor_part}"; then
			ewarn "You are performing an upgrade that is not backwards-compatible"
			ewarn "and you need to upgrade to ${PN}-${minor_part} on all your devices."
			ewarn "Please read: https://github.com/abraunegg/onedrive/releases/tag/v${PV}"
			break
		fi
	done
	optfeature "Single Sign-On via Intune" sys-apps/intune-portal
}

pkg_postrm() {
	xdg_icon_cache_update
}
