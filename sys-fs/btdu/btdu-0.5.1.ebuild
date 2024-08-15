# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# gdc-13 is disabled due to: https://gcc.gnu.org/PR111650
# gdc-14 is disabled due to: https://gcc.gnu.org/PR116373
DLANG_COMPAT=( dmd-2_10{6..9} ldc2-1_3{5..9} )
DUB_DEPENDENCIES=(
	"ae@0.0.3236"
	"btdu@0.5.1"
	"btrfs@0.0.18"
	"emsi_containers@0.9.0"
	"ncurses@1.0.0"
)
inherit dlang-single dub

DESCRIPTION="Sampling disk usage profiler for btrfs"
HOMEPAGE="https://github.com/CyberShadow/btdu"
SRC_URI="${DUB_DEPENDENCIES_URIS}"

LICENSE="GPL-2"
LICENSE+=" Boost-1.0 GPL-2 MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
# Relevant tests require a btrfs filesystem.
RESTRICT="test"

COMMON_DEPEND="sys-libs/zlib sys-libs/ncurses:="
DEPEND+=" ${COMMON_DEPEND}"
RDEPEND+=" ${COMMON_DEPEND}"

DOCS=( README.md CONCEPTS.md )

src_test() {
	# Enabling unittests runs the unittests in the dependencies which
	# may not all be relevant for this package.
	edub test --build=unittest
}

src_install() {
	dobin "${S}/btdu"
	doman btdu.1
	einstalldocs
}
