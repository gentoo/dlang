# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KEYWORDS="-* amd64 x86"
YEAR=2014
ARCHIVE="linux.zip"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.066-no-narrowing.patch"
	"${FILESDIR}/2.068-replace-bits-mathdef-h.patch"
	"${FILESDIR}/2.066.1-phobos-makefile.patch"
	"${FILESDIR}/2.073-fix-segv-in-evalu8.patch"
	"${FILESDIR}/2.065-link-32-bit-shared-lib-with-ld.bfd.patch"
)
