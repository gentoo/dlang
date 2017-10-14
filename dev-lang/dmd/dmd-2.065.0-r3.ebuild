# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2014
ARCHIVE="linux.zip"

inherit dmd

PATCHES=( "${FILESDIR}/2.065-no-narrowing.patch" "${FILESDIR}/2.065-makefile-multilib.patch" )
