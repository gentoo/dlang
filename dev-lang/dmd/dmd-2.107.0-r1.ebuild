# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KEYWORDS="-* ~amd64 ~x86"
DLANG_COMPAT=( dmd-2_{106..107} gdc-13 ldc2-1_{35..36} )

inherit dmd-r1

PATCHES=(
	"${FILESDIR}/2.107-dmd-r1-link-32-bit-shared-lib-with-ld.bfd.patch"
)
