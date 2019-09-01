# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit multilib-build cmake-utils eapi7-ver llvm

MY_PV="${PV//_/-}"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://ldc-developers.github.com/ldc"
KEYWORDS="amd64 ~arm x86"
LICENSE="BSD"
SLOT="$(ver_cut 1-2)/$(ver_cut 3)"

IUSE=""

# We support LLVM 3.7 through 5.
RDEPEND="|| (
		sys-devel/llvm:5
		sys-devel/llvm:4
		>=sys-devel/llvm-3.7:0
	)
	<sys-devel/llvm-6:=
	>=dev-libs/libconfig-1.4.7
	>=app-eselect/eselect-dlang-20140709"
DEPEND=">=dev-util/cmake-2.8
	${RDEPEND}"
LLVM_MAX_SLOT=5

# For now, we support amd64 multilib. Anyone is free to add more support here.
MULTILIB_COMPAT=( abi_x86_{32,64} )

detect_hardened() {
	gcc --version | grep -o Hardened
}

src_configure() {
	if use abi_x86_32 && use abi_x86_64; then
		sed -i 's#@ADDITIONAL_DEFAULT_LDC_SWITCHES@#,"-L-rpath=@CMAKE_INSTALL_PREFIX@/lib@LIB_SUFFIX@:@CMAKE_INSTALL_PREFIX@/lib@MULTILIB_SUFFIX@"@ADDITIONAL_DEFAULT_LDC_SWITCHES@#' ldc2_install.conf.in || die "Cannot patch ldc2_install.conf.in"
	else
		sed -i 's#@ADDITIONAL_DEFAULT_LDC_SWITCHES@#,"-L-rpath=@CMAKE_INSTALL_PREFIX@/lib@LIB_SUFFIX@"@ADDITIONAL_DEFAULT_LDC_SWITCHES@#' ldc2_install.conf.in || die "Cannot patch ldc2_install.conf.in"
	fi
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX=/usr/lib/ldc2/$(ver_cut 1-2)
	)
	use abi_x86_32 && use abi_x86_64 && mycmakeargs+=( -DMULTILIB=ON )
	detect_hardened && mycmakeargs+=( -DADDITIONAL_DEFAULT_LDC_SWITCHES=', "-relocation-model=pic"' )
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
