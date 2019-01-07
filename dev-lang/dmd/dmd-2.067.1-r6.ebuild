# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2015
ARCHIVE="linux.zip"

inherit dmd eutils

PATCHES=(
	"${FILESDIR}/2.067-no-narrowing.patch"
	"${FILESDIR}/2.068-replace-bits-mathdef-h.patch"
	"${FILESDIR}/2.073-fix-segv-in-evalu8.patch"
	"${FILESDIR}/2.065-link-32-bit-shared-lib-with-ld.bfd.patch"
)
