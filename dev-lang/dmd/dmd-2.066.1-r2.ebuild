# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2014
ARCHIVE="linux.zip"

inherit dmd

PATCHES="2.066.1-phobos-makefile.patch"

FILES=(
	[1]="license.txt                license.txt"
	[2]="druntime/LICENSE           druntime-LICENSE.txt"
	[3]="druntime/README.md         druntime-README.md"
	[4]="phobos/LICENSE_1_0.txt     phobos-LICENSE_1_0.txt"
	[5]="dmd/src/backendlicense.txt dmd-backendlicense.txt"
	[6]="dmd/src/artistic.txt       dmd-artistic.txt"
	[7]="dmd/src/gpl.txt            dmd-gpl.txt"
)
