# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2020
DLANG_VERSION_RANGE="2.076-"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.078-link-32-bit-shared-lib-with-ld.bfd.patch"
)
