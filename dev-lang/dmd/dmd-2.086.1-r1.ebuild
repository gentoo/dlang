# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="-* amd64 x86"
YEAR=2019
DLANG_VERSION_RANGE="2.073-"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.082-allow-deprecations.patch"
	"${FILESDIR}/2.078-link-32-bit-shared-lib-with-ld.bfd.patch"
)

dmd_src_prepare_extra() {
	# Copy default DDOC theme file into resource directory
	mkdir "dmd/res" || die "Failed to create 'dmd/res' directory"
	cp "${FILESDIR}/2.086-default_ddoc_theme.ddoc" "dmd/res/default_ddoc_theme.ddoc" || die "Failed to copy 'default_ddoc_theme.ddoc' file into 'src/res' directory."

	# Copy missing config.d
	cp "${FILESDIR}/2.086-config.d" "dmd/config.d" || die "Failed to copy 'config.d' file into 'dmd' directory."
}
