# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2017
DLANG_VERSION_RANGE="2.067-2.073"

inherit dmd

FILES=(
	[1]="license.txt                license.txt"
	[2]="druntime/LICENSE           druntime-LICENSE.txt"
	[3]="druntime/README.md         druntime-README.md"
	[4]="phobos/LICENSE_1_0.txt     phobos-LICENSE_1_0.txt"
	[5]="dmd/src/backendlicense.txt dmd-backendlicense.txt"
	[6]="dmd/src/boostlicense.txt   dmd-boostlicense.txt"
)

dmd_src_prepare_extra() {
	# Copy default DDOC theme file into resource directory
	mkdir "dmd/res" || die "Failed to create 'dmd/res' directory"
	cp "${FILESDIR}/2.073-default_ddoc_theme.ddoc" "dmd/res/default_ddoc_theme.ddoc" || die "Failed to copy 'default_ddoc_theme.ddoc' file into 'src/res' directory."
}
