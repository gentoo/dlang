# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KEYWORDS="-* amd64 x86"
YEAR=2013
ARCHIVE="zip"
SONAME="libphobos2.so.0.64.0"

inherit dmd

PATCHES=(
	"${FILESDIR}/2.064-no-narrowing.patch"
	"${FILESDIR}/2.063-replace-bits-mathdef-h.patch"
	"${FILESDIR}/2.064-makefile-multilib.patch"
	"${FILESDIR}/2.073-fix-segv-in-evalu8.patch"
	"${FILESDIR}/2.064-link-32-bit-shared-lib-with-ld.bfd.patch"
)

dmd_src_prepare_extra() {
	# Move dmd.conf man page into correct slot.
	mkdir man/man5 || die "Failed to create man/man5."
	mv man/man1/dmd.conf.5 man/man5/dmd.conf.5 || die "Failed to move man/man1/dmd.conf.5."
}
