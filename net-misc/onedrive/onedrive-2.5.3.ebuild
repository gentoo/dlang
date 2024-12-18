# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( dmd-2_{106..109} ldc2-1_{35..39} )
inherit bash-completion-r1 dlang-single systemd

DESCRIPTION="Free Client for OneDrive on Linux"
HOMEPAGE="https://abraunegg.github.io/"
SRC_URI="https://codeload.github.com/abraunegg/onedrive/tar.gz/v${PV} -> ${P}.tar.gz"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS=""
# no straight forward way to run unittests. Probably need to do DFLAGS=-unittest econf
IUSE="debug libnotify"
RESTRICT=test

REQUIRED_USE=${DLANG_REQUIRED_USE}
RDEPEND="
	${DLANG_DEPS}
	>=dev-db/sqlite-3.7.15:3
	net-misc/curl
	libnotify? ( x11-libs/libnotify )
"
DEPEND="
	${RDEPEND}
	virtual/pkgconfig
"
BDEPEND=${DLANG_DEPS}

src_configure() {
	DCFLAGS="${DCFLAGS} ${DLANG_LDFLAGS}" econf \
		--disable-version-check --enable-completions \
		$(use_enable debug) $(use_enable libnotify notifications) \
		--with-zsh-completion-dir=/usr/share/zsh/site-functions \
		--with-bash-completion-dir="$(get_bashcompdir)" \
		--with-fish-completion-dir=/usr/share/fish/completions \
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

	local old_ver minor_part="$(ver_cut 1-2)"
	for old_ver in ${REPLACING_VERSIONS}; do
		if ver_test "${old_ver}" -lt "${minor_part}"; then
			ewarn "You are performing an upgrade that is not backwards-compatible"
			ewarn "and you need to upgrade to ${PN}-${minor_part} on all your devices."
			ewarn "Please read: https://github.com/abraunegg/onedrive/releases/tag/v${PV}"
			break
		fi
	done
}
