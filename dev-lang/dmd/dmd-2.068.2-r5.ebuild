# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2015
DLANG_VERSION_RANGE="2.063-"

inherit dmd

PATCHES=( "${FILESDIR}/2.067-no-narrowing.patch" "${FILESDIR}/replace-bits-mathdef-h.patch" )
