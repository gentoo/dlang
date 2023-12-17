# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib-build cmake llvm

MY_PV="${PV//_/-}"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://github.com/ldc-developers/ldc"
KEYWORDS="amd64 ~arm64 x86"
LICENSE="BSD"
SLOT="$(ver_cut 1-2)/$(ver_cut 3)"

IUSE="static-libs"

# Upstream supports LLVM 9.0 through 14.0.
RDEPEND="dev-util/ninja
	|| (
		sys-devel/llvm:14
	)
	<sys-devel/llvm-15:=
	>=app-eselect/eselect-dlang-20140709"
DEPEND="${RDEPEND}"
LLVM_MAX_SLOT=14
PATCHES="${FILESDIR}/ldc2-1.15.0-link-defaultlib-shared.patch"

# For now, we support amd64 multilib. Anyone is free to add more support here.
MULTILIB_COMPAT=( abi_x86_{32,64} )

# Upstream supports "2.079-"
DLANG_VERSION_RANGE="2.075-2.080 2.082-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

src_prepare() {
	cmake_src_prepare
}

d_src_configure() {
	# Make sure libphobos2 is installed into ldc2's directory.
	export LIBDIR_${ABI}="${LIBDIR_HOST}"
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX=/usr/lib/ldc2/$(ver_cut 1-2)
		-DD_COMPILER="${DMD} $(dlang_dmdw_dcflags)"
		-DLDC_WITH_LLD=OFF
	)
	use static-libs && mycmakeargs+=( -DBUILD_SHARED_LIBS=BOTH ) || mycmakeargs+=( -DBUILD_SHARED_LIBS=ON )
	use abi_x86_32 && use abi_x86_64 && mycmakeargs+=( -DMULTILIB=ON )
	cmake_src_configure
}

d_src_compile()
{
	cmake_src_compile
}

d_src_install() {
	cmake_src_install

	rm -rf "${ED}"/usr/share/bash-completion
}

pkg_postinst() {
	# Update active ldc2
	"${ROOT}"/usr/bin/eselect dlang update ldc2
}

pkg_postrm() {
	"${ROOT}"/usr/bin/eselect dlang update ldc2
}
