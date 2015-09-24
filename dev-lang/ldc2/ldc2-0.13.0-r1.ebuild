# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=5

inherit cmake-utils versionator

MY_PV="$(replace_version_separator '_' '-')"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://ldc-developers.github.com/ldc"
KEYWORDS="x86 amd64 ~ppc64"
LICENSE="BSD"
SLOT="$(get_version_component_range 1-2)/1"
IUSE=""

RDEPEND=">=sys-devel/llvm-3.1-r2
	>=dev-libs/libconfig-1.4.7
	>=app-admin/eselect-dlang-20140709"
DEPEND=">=dev-util/cmake-2.8
	${RDEPEND}"

src_prepare() {
	EPATCH_OPTS="-p1"
	epatch "${FILESDIR}/ldc2-$(version_format_string '$1.$2.$3')-issue642.patch"
}

src_configure() {
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX=/opt/ldc2-$(get_version_component_range 1-2)
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_make
}

src_install() {
	cmake-utils_src_install

	rm -rf "${ED}"/usr/share/bash-completion
}

pkg_postinst() {
	# Update active ldc2
	"${ROOT}"/usr/bin/eselect dlang update ldc2
}

pkg_postrm() {
	"${ROOT}"/usr/bin/eselect dlang update ldc2
}
