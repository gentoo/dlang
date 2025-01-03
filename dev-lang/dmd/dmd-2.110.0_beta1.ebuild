# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#KEYWORDS="-* ~amd64 ~x86"
DLANG_COMPAT=( dmd-2_{106..109} gdc-1{3,4} ldc2-1_{35..40} )

inherit dmd-r1

PATCHES=(
	"${FILESDIR}/2.107-dmd-r1-link-32-bit-shared-lib-with-ld.bfd.patch"
)
