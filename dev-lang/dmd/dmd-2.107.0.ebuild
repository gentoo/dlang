# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KEYWORDS="-* ~amd64 ~x86"
YEAR=2024
DLANG_VERSION_RANGE="2.100-2.107"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.105-link-32-bit-shared-lib-with-ld.bfd.patch"
	# See https://github.com/dlang/phobos/pull/8820
	"${FILESDIR}/2.107-phobos-change-DMD_DIR-meaning.patch"
	"${FILESDIR}/2.107-druntime-support-DMD_DIR.patch"
)
