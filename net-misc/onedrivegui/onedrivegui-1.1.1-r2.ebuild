# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

M_PN=OneDriveGUI

DISTUTILS_SINGLE_IMPL=1
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

RDEPEND=">=net-misc/onedrive-2.5
	!net-misc/onedrivegui-bin
	dev-python/requests
	dev-python/pyside[gui(+),webengine(+),widgets(+)]
"

LICENSE="GPL-3"
SLOT="0"

src_prepare() {
	cp "${FILESDIR}/setup-onedrivegui.py" "${S}/setup.py" || die
	cp "${FILESDIR}/setup-onedrivegui-fix1.cfg" "${S}/setup.cfg" || die
	cp "${FILESDIR}/OneDriveGUI-fix1.desktop" "${S}/src/OneDriveGUI.desktop" || die
	cp "${FILESDIR}/wrapper-module.py" "${S}/src/__main__.py" || die

	#fix python package version
	sed -i "s/^version = _VERSION$/version = ${PV}/g" "${S}/setup.cfg" || die

	# Remove unused leftovers
	rm -f "${S}/src/ui/"*_ui.py || die

	# Fix broken image references
	sed -i \
	    -e 's|\.\./\.\./\.\./OneDriveGUI_POC_recovered-multi/|../resources/images/|g' \
	    "${S}/src/ui/"*.py || die

	# Patch file to make it work as a module
	sed -i \
	    -e 's/^from version\b/from .version/' \
	    -e 's/^from ui\./from .ui./' \
	    -e '/^GUI_SETTINGS_FILE =/a\'$'\n''gui_settings = None\nglobal_config = None\ntemp_global_config = None\main_window = None' \
	    -e '/^if __name__ == "__main__":/a\'$'\n''    global gui_settings, global_config, temp_global_config, main_window' \
	    -e 's/if __name__ == "__main__":/def main():/' \
	    -e '$a\'$'\n''\nif __name__ == "__main__":\n    main()' \
	    "${S}/src/OneDriveGUI.py" || die

	python_fix_shebang "${S}/src/OneDriveGUI.py"

	default
}
