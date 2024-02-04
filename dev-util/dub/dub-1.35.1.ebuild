# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Package and build management system for D"
HOMEPAGE="https://code.dlang.org/"
LICENSE="MIT"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE="debug"

GITHUB_URI="https://codeload.github.com/dlang"
SRC_URI="${GITHUB_URI}/${PN}/tar.gz/v${PV} -> ${PN}-${PV}.tar.gz"

# Upstream recommends the latest version available
DLANG_VERSION_RANGE="2.100-2.106"
DLANG_PACKAGE_TYPE="single"

inherit dlang

d_src_compile() {
	local imports=source versions="DubApplication DubUseCurl"
	dlang_compile_bin bin/dub $(<build-files.txt)

	## Currently broken with gdc
	# Generate man pages
	#bin/dub scripts/man/gen_man.d || die "Could not generate man pages."
}

d_src_test() {
	echo "Test phase disabled due to multiple problems."
	#DUB="${S}/bin/dub" test/run-unittest.sh || die "Test phase failed"
}

d_src_install() {
	dobin bin/dub
	dodoc README.md

	## Currently broken with gdc
	# All the files in the directory below, with the exception of gen_man.d and README, are man pages.
	# To keep the ebuild simple, we will just glob on the files that end in .1 since there are currently
	# no man pages in a different section.
	#doman scripts/man/*.1
}
