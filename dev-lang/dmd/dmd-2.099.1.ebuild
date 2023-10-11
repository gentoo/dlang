# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KEYWORDS="-* amd64 x86"
YEAR=2022
DLANG_VERSION_RANGE="2.076-2.080 2.082 2.084-2.100"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.097-link-32-bit-shared-lib-with-ld.bfd.patch"
)
