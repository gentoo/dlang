# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic multilib-build cmake

MY_PV="${PV//_/-}"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://github.com/ldc-developers/ldc"
KEYWORDS="~amd64 ~arm64 ~x86"
LICENSE="BSD"
# For first bump, set the subslot below to 0 and only increase if there
# is an actual ABI bkreakage.
SLOT="$(ver_cut 1-2)/$(ver_cut 3)"

IUSE="static-libs"
RESTRICT="test"

# Upstream supports LLVM 11.0 through 17.0.
LLVM_COMPAT=( {15..17} )
DLANG_COMPAT=( dmd-2_{106..107} gdc-13 ldc2-1_{35..36} )

inherit llvm-r1 dlang-single

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND="
	${DLANG_DEPS}
	$(llvm_gen_dep '
	  sys-devel/llvm:${LLVM_SLOT}=
	')
"
IDEPEND=">=app-eselect/eselect-dlang-20140709"
RDEPEND="
	${DEPEND}
	${IDEPEND}
"
BDEPEND=${DLANG_DEPS}

PATCHES="${FILESDIR}/ldc2-1.15.0-link-defaultlib-shared.patch"

src_configure() {
	# We disable assertions so we have to apply the same workaround as for
	# sys-devel/llvm: add -DNDEBUG to CPPFLAGS.
	local CPPFLAGS="${CPPFLAGS} -DNDEBUG"
	# https://bugs.gentoo.org/show_bug.cgi?id=922590
	append-flags -fno-strict-aliasing
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}"/usr/lib/ldc2/$(ver_cut 1-2)
		-DD_COMPILER="$(dlang_get_dmdw) $(dlang_get_dmdw_dcflags)"
		-DLDC_WITH_LLD=OFF
		-DCOMPILE_D_MODULES_SEPARATELY=ON
		-DLDC_ENABLE_ASSERTIONS=OFF
		-DBUILD_SHARED_LIBS=$(usex static-libs BOTH ON)
	)
	use abi_x86_32 && use abi_x86_64 && mycmakeargs+=( -DMULTILIB=ON )

	cmake_src_configure
}

src_install() {
	cmake_src_install

	rm -rf "${ED}"/usr/share/bash-completion
}

pkg_postinst() {
	# Update active ldc2
	"${EROOT}"/usr/bin/eselect dlang update ldc2
}

pkg_postrm() {
	"${EROOT}"/usr/bin/eselect dlang update ldc2
}
