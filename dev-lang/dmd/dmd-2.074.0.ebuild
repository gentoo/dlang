# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* ~amd64 ~x86"
YEAR=2017
DLANG_VERSION_RANGE="2.067-"

inherit dmd

dmd_src_prepare_extra() {
	# Copy VERSION file into dmd directory
	mkdir "src/res" || die "Failed to create 'src/res' directory"
	cp "${FILESDIR}/default_ddoc_theme.ddoc" "src/res/default_ddoc_theme.ddoc" || die "Failed to copy default_ddoc_theme.ddoc file into 'src/res' directory."
}
