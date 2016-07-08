# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2013
ARCHIVE="zip"
SONAME="libphobos2.so.0.2.0"

inherit dmd

FILES=(
	[1]="license.txt                 license.txt"
	[2]="src/druntime/LICENSE        druntime-LICENSE.txt"
	[3]="src/druntime/README         druntime-README.txt"
	[4]="${FILESDIR}/LICENSE_1_0.txt phobos-LICENSE_1_0.txt"
	[5]="src/dmd/backendlicense.txt  dmd-backendlicense.txt"
	[6]="src/dmd/artistic.txt        dmd-artistic.txt"
	[7]="src/dmd/gpl.txt             dmd-gpl.txt"
)

dmd_src_prepare_extra() {
	# Copy VERSION file into dmd directory
	cp src/VERSION src/dmd/VERSION || die "Failed to copy VERSION file into dmd directory."

	# Move dmd.conf man page into correct slot.
	mkdir man/man5 || die "Failed to create man/man5."
	mv man/man1/dmd.conf.5 man/man5/dmd.conf.5 || die "Failed to move man/man1/dmd.conf.5."
}
