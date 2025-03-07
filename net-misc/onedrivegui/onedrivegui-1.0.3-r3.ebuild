# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

M_PN=OneDriveGUI
DISTUTILS_USE_PEP517=no
PYTHON_COMPAT=(python3_{10..13})

DESCRIPTION="A simple GUI for OneDrive Linux client, with multi-account support."
HOMEPAGE="https://github.com/bpozdena/OneDriveGUI"
LICENSE="GPL-3"
SLOT="0"

inherit desktop distutils-r1 xdg-utils

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/bpozdena/${M_PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/bpozdena/${M_PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${M_PN}-${PV}"
fi

RESTRICT=test

RDEPEND="<net-misc/onedrive-2.5
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/pyside[gui(+),webengine(+),widgets(+),${PYTHON_USEDEP}]
"

python_install() {
	python_moduleinto "${M_PN}"
	# Slightly inefficient as it duplicates the resource folder across
	# python implementations but the project relies on those files being
	# placed relative to the code.
	python_domodule src/*

	# The main file has to live alongside the ui module so make a
	# separate script as the entry point.
	#
	# There is no main function and its implementation in the code is
	# non-trivial so make a shell script.
	local main_file="$(python_get_sitedir)/${M_PN}/${M_PN}.py"
	python_newexe - "${M_PN}" <<-EOF
		#!/bin/sh
		exec "${EPREFIX}/usr/bin/${EPYTHON}" "${main_file}" "\${@}"
	EOF
}

python_install_all() {
	doicon src/resources/images/"${M_PN}.png"
	make_desktop_entry "${M_PN}" "${M_PN}" "${M_PN}" \
					   "Network;FileTransfer;Monitor" \
					   "StartupNotify=true\nTerminal=false"

	distutils-r1_python_install_all
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
