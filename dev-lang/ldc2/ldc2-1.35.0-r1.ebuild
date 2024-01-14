# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib-build cmake llvm

MY_PV="${PV//_/-}"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://github.com/ldc-developers/ldc"
KEYWORDS="~amd64 ~arm64 ~x86"
LICENSE="BSD"
SLOT="$(ver_cut 1-2)/$(ver_cut 3)"

IUSE="static-libs"

# Upstream supports LLVM 11.0 through 16.0.
DEPEND="
	|| (
		sys-devel/llvm:16
		sys-devel/llvm:15
	)
	<sys-devel/llvm-17:="
IDEPEND=">=app-eselect/eselect-dlang-20140709"
RDEPEND="
	${DEPEND}
	${IDEPEND}"

LLVM_MAX_SLOT=16
PATCHES="${FILESDIR}/ldc2-1.15.0-link-defaultlib-shared.patch"

# For now, we support amd64 multilib. Anyone is free to add more support here.
MULTILIB_COMPAT=( abi_x86_{32,64} )

# Upstream supports "2.079-"
DLANG_VERSION_RANGE="2.100-2.106"
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
		-DCOMPILE_D_MODULES_SEPARATELY=ON
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
