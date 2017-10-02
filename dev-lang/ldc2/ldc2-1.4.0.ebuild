# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils versionator

MY_PV="$(replace_version_separator '_' '-')"
MY_P="ldc-${MY_PV}-src"
SRC_URI="https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://ldc-developers.github.com/ldc"
KEYWORDS="~x86 ~amd64 ~arm"
LICENSE="BSD"
SLOT="$(get_version_component_range 1-2)/$(get_version_component_range 3)"

IUSE="static-libs"

RDEPEND=">=sys-devel/llvm-3.7:=
	<sys-devel/llvm-5.1:=
	>=app-eselect/eselect-dlang-20140709"
DEPEND=">=dev-util/cmake-2.8
	${RDEPEND}"

DLANG_VERSION_RANGE="2.068-"
DLANG_PACKAGE_TYPE="single"

inherit dlang

detect_hardened() {
	gcc --version | grep -o Hardened
}

src_prepare() {
	sed -i 's/@MULTILIB_ADDITIONAL_INSTALL_PATH@/"-L-rpath", "-L@CMAKE_INSTALL_LIBDIR@",/' ldc2_install.conf.in || die "Cannot patch ldc2_install.conf.in"
	if use static-libs; then
		sed -i 's/phobos2-ldc,druntime-ldc/phobos2-ldc-shared,druntime-ldc-shared/;s/phobos2-ldc-debug,druntime-ldc-debug/phobos2-ldc-debug-shared,druntime-ldc-debug-shared/' ldc2_install.conf.in || die "Cannot patch ldc2_install.conf.in"
	fi
	eapply_user
}

d_src_configure() {
	# Make sure libphobos2 is installed into ldc2's directory.
	export LIBDIR_${ABI}="${LIBDIR_HOST}"
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX=/opt/ldc2-$(get_version_component_range 1-2)
		-DD_COMPILER="${DMD}"
		-DD_COMPILER_DMD_COMPAT=1
	)
	use static-libs && mycmakeargs+=( -DBUILD_SHARED_LIBS=BOTH ) || mycmakeargs+=( -DBUILD_SHARED_LIBS=ON )
	detect_hardened && mycmakeargs+=( -DADDITIONAL_DEFAULT_LDC_SWITCHES=', "-relocation-model=pic"' )
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
