# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Don't use this package, use dev-util/gdmd:0"
HOMEPAGE="https://www.gdcproject.org/"
S="${WORKDIR}"

LICENSE="GPL-3+"
SLOT="$(ver_cut 1)"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="test"

date=$(ver_cut 2)
RDEPEND=">=dev-util/gdmd-${date}:0[dlang_targets_gdc-${SLOT}(-)]"
