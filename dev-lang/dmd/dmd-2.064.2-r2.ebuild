# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2013
ARCHIVE="zip"
SONAME="libphobos2.so.0.64.0"

inherit dmd

PATCHES="2.064-makefile-multilib.patch"

FILES=(
	[1]="license.txt                 license.txt"
	[2]="druntime/LICENSE            druntime-LICENSE.txt"
	[3]="druntime/README             druntime-README.txt"
	[4]="${FILESDIR}/LICENSE_1_0.txt phobos-LICENSE_1_0.txt"
	[5]="dmd/src/backendlicense.txt  dmd-backendlicense.txt"
	[6]="dmd/src/artistic.txt        dmd-artistic.txt"
	[7]="dmd/src/gpl.txt             dmd-gpl.txt"
)

dmd_src_prepare_extra() {
	# Move dmd.conf man page into correct slot.
	mkdir man/man5 || die "Failed to create man/man5."
	mv man/man1/dmd.conf.5 man/man5/dmd.conf.5 || die "Failed to move man/man1/dmd.conf.5."
}
