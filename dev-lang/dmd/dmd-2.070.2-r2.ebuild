# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2016
DLANG_VERSION_RANGE="2.067-2.073"

inherit dmd

PATCHES="2.070-disable-dwarf.patch"
