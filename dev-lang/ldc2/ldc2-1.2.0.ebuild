# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

inherit cmake-utils versionator

MY_PV="$(replace_version_separator '_' '-')"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
PATCHES=""
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://ldc-developers.github.com/ldc"
KEYWORDS="~x86 ~amd64 ~arm"
LICENSE="BSD"
SLOT="$(get_version_component_range 1-2)/1"
IUSE=""

RDEPEND=">=dev-libs/libconfig-1.4.7
	>=app-eselect/eselect-dlang-20140709"
DEPEND=">=dev-util/cmake-2.8
	>=sys-devel/llvm-3.5
	${RDEPEND}"

DLANG_VERSION_RANGE="2.068-2.073"
DLANG_PACKAGE_TYPE="single"

inherit dlang

d_src_configure() {
	# Make sure libphobos2 is installed into ldc2's directory.
	export LIBDIR_${ABI}="${LIBDIR_HOST}"
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX=/opt/ldc2-$(get_version_component_range 1-2)
		-DD_COMPILER="${DMD}"
		-DD_COMPILER_DMD_COMPAT=1
	)
	cmake-utils_src_configure
}

d_src_compile() {
	cmake-utils_src_make
}

d_src_install() {
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
