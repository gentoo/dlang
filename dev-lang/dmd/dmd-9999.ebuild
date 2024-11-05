# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} != *9999* ]]; then
	KEYWORDS="-* ~amd64 ~x86"
else
	BOOTSTRAP_VERSION=2.109.1
fi
DLANG_COMPAT=( dmd-2_{106..109} gdc-1{3,4} ldc2-1_{35..39} )

inherit dmd-r1

# Support the 9999 directory name in /usr/lib/dmd instead of 2.XXX
[[ ${PV} == *9999* ]] && IDEPEND=">=app-eselect/eselect-dlang-20241105"

PATCHES=(
	"${FILESDIR}/2.107-dmd-r1-link-32-bit-shared-lib-with-ld.bfd.patch"
)
