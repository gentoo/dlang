# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2017
DLANG_VERSION_RANGE="2.067-2.073"

inherit dmd

FILES=(
	[1]="license.txt                license.txt"
	[2]="src/druntime/LICENSE       druntime-LICENSE.txt"
	[3]="src/druntime/README.md     druntime-README.md"
	[4]="src/phobos/LICENSE_1_0.txt phobos-LICENSE_1_0.txt"
	[5]="src/dmd/backendlicense.txt dmd-backendlicense.txt"
	[6]="src/dmd/boostlicense.txt   dmd-boostlicense.txt"
)

dmd_src_prepare_extra() {
	# Copy default DDOC theme file into resource directory
	mkdir "src/res" || die "Failed to create 'src/res' directory"
	cp "${FILESDIR}/default_ddoc_theme.ddoc" "src/res/default_ddoc_theme.ddoc" || die "Failed to copy default_ddoc_theme.ddoc file into 'src/res' directory."
}
