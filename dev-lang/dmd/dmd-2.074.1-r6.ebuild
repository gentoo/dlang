# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KEYWORDS="-* amd64 x86"
YEAR=2017
DLANG_VERSION_RANGE="2.067-2.080"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.074-fix-segv-in-evalu8.patch"
	"${FILESDIR}/2.074-fix-out-of-bounds-in-evalu8.patch"
	"${FILESDIR}/2.074-link-32-bit-shared-lib-with-ld.bfd.patch"
)

dmd_src_prepare_extra() {
	# Copy default DDOC theme file into resource directory
	mkdir "dmd/res" || die "Failed to create 'dmd/res' directory"
	cp "${FILESDIR}/2.073-default_ddoc_theme.ddoc" "dmd/res/default_ddoc_theme.ddoc" || die "Failed to copy 'default_ddoc_theme.ddoc' file into 'src/res' directory."
}
