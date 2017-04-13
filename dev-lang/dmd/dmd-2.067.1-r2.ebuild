# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2015
ARCHIVE="linux.zip"

inherit dmd

FILES=(
	[1]="license.txt                license.txt"
	[2]="src/druntime/LICENSE       druntime-LICENSE.txt"
	[3]="src/druntime/README.md     druntime-README.md"
	[4]="src/phobos/LICENSE_1_0.txt phobos-LICENSE_1_0.txt"
	[5]="src/dmd/backendlicense.txt dmd-backendlicense.txt"
	[6]="src/dmd/boostlicense.txt   dmd-boostlicense.txt"
)
