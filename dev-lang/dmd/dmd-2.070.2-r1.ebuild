# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2016
DLANG_VERSION_RANGE="2.067-2.073"

inherit dmd

PATCHES="2.070-disable-dwarf.patch"

FILES=(
	[1]="license.txt                license.txt"
	[2]="druntime/LICENSE           druntime-LICENSE.txt"
	[3]="druntime/README.md         druntime-README.md"
	[4]="phobos/LICENSE_1_0.txt     phobos-LICENSE_1_0.txt"
	[5]="dmd/src/backendlicense.txt dmd-backendlicense.txt"
	[6]="dmd/src/boostlicense.txt   dmd-boostlicense.txt"
)
