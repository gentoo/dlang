# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2015
DLANG_VERSION_RANGE="2.067-2.073"

inherit dmd

PATCHES=( "${FILESDIR}/2.069-no-narrowing.patch" "${FILESDIR}/2.073-fix-segv-in-evalu8.patch" )
