# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Upstream supports LLVM 15.0 through 18.0.
LLVM_COMPAT=( {15..18} )
PYTHON_COMPAT=( python3_{10..13} )
inherit cmake llvm-r1 multilib-build multiprocessing python-any-r1 toolchain-funcs

PATCH_VER=1
PATCH_TAG_NAME="${PV}-patches-${PATCH_VER}"
PATCH_URL_BASE="https://github.com/the-horo/ldc-patches/archive/refs/tags"

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://github.com/ldc-developers/ldc"
MY_PV="${PV//_/-}"
MY_P="ldc-${MY_PV}-src"
SRC_URI="
	https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz
	${PATCH_URL_BASE}/${PATCH_TAG_NAME}.tar.gz -> ${P}-patches-${PATCH_VER}.tar.gz
"
S=${WORKDIR}/${MY_P}
LICENSE="BSD"
# dmd code + runtime lib, see dmd-r1.eclass for more details
LICENSE+=" Boost-1.0 || ( CC0-1.0 Apache-2.0 ) BZIP2 ZLIB curl public-domain"
# llvm bits
LICENSE+=" Apache-2.0-with-LLVM-exceptions UoI-NCSA"
# old gdc + dmd code
LICENSE+=" GPL-2+ Artistic"

# Only increase subslot in case of ABI breakage
SLOT="$(ver_cut 1-2)/0"
KEYWORDS="~amd64 ~arm64 ~x86"

IUSE="static-libs test"
RESTRICT="!test? ( test )"

DLANG_COMPAT=( dmd-2_{106..109} gdc-1{3..4} ldc2-1_{35..39} )

inherit dlang-single

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND="
	${DLANG_DEPS}
	$(llvm_gen_dep '
	  llvm-core/llvm:${LLVM_SLOT}=
	')
	net-misc/curl[${MULTILIB_USEDEP}]
"
IDEPEND=">=app-eselect/eselect-dlang-20140709"
RDEPEND="
	${DEPEND}
	${IDEPEND}
"
BDEPEND="
	${DLANG_DEPS}
	test? (
		  ${PYTHON_DEPS}
		  $(python_gen_any_dep '
			  dev-python/lit[${PYTHON_USEDEP}]
		  ')
	)
"

python_check_deps() {
	python_has_version "dev-python/lit[${PYTHON_USEDEP}]"
}

pkg_setup() {
	dlang_setup
	llvm-r1_pkg_setup
	use test && python_setup
}

src_prepare(){
	apply_patches

	# Disable GDB tests by passing GDB_FLAGS=OFF
	# Put this here to avoid trigerring reconfigurations later on.
	sed -i 's/\(GDB_FLAGS=\)\S\+/\1OFF/' "${S}"/tests/dmd/CMakeLists.txt || die

	# This test fails with >=gcc-14, fixed in newer versions.
	rm -r "${S}"/tests/dmd/compilable/stdcheaders.c || die

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DD_VERSION=2
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}"/usr/lib/ldc2/$(ver_cut 1-2)
		-DD_COMPILER="$(dlang_get_dmdw) $(dlang_get_dmdw_dcflags)"
		-DLDC_WITH_LLD=OFF
		-DCOMPILE_D_MODULES_SEPARATELY=ON
		-DLDC_ENABLE_ASSERTIONS=OFF
		-DBUILD_SHARED_LIBS=$(usex static-libs BOTH ON)
		-DLDC_BUNDLE_LLVM_TOOLS=OFF
		-DCOMPILER_RT_BASE_DIR="${EPREFIX}"/usr/lib
		-DCOMPILER_RT_LIBDIR_OS=linux
		-DTEST_COMPILER_RT_LIBRARIES=none
	)
	use abi_x86_32 && use abi_x86_64 && mycmakeargs+=( -DMULTILIB=ON )

	cmake_src_configure
}

src_test()
{
	# Call the same tests that .github/actions/main.yml does

	local jobs=$(get_makeopts_jobs)

	### 4a-test-ldc2 ###

	# We build it explicitly so that MAKEOPTS is respected
	cmake_src_compile ldc2-unittest
	cmake_src_test -R ldc2-unittest

	### 4b-test-lit ###

	# Instead of running cmake_src_test -R lit-tests we call lit directly
	pushd "${BUILD_DIR}"/tests > /dev/null || die
	"${EPYTHON}" runlit.py -j${jobs} -v . || die 'lit tests failed'
	popd > /dev/null || die

	### 4c-test-dmd ###

	# Calss gcc directly
	sed -i "s/gcc/$(tc-getCC)/" "${S}"/tests/dmd/runnable/importc-test1.sh || die

	# These tests invoke a runner that runs the tests in parallel so
	# specify the jobs only to the runner and not cmake. I'm pretty sure
	# that some of the tests can't be run simultaniously by multiple
	# runners so keep the cmake jobs to 1.
	DMD_TESTSUITE_MAKE_ARGS=-j${jobs} cmake_src_test -j 1 -V -R dmd-testsuite

	### 4d-test-libs ###

	# We compile the tests first so that $MAKEOPTS is respect, if
	# compiled during the tests, nproc jobs will be used.
	cmake_src_compile all-test-runners

	local CMAKE_SKIP_TESTS=(
		# These are the targets tested above
		ldc2-unittest
		lit-tests
		dmd-testsuite

		# These tests call gdb
		druntime-test-exceptions
		# Require valgrind
		druntime-test-gc
		druntime-test-valgrind

		# This one fails due to an uncaught error, probably due to the
		# sandbox.
		druntime-test-cycles
	)
	if [[ ${ARCH} == arm64 ]]; then
		# https://github.com/ldc-developers/ldc/issues/4613

		# fails due to "innacuracy"
		CMAKE_SKIP_TESTS+=( std.internal.math.gammafunction )
		# Bad code generation with optimizations?
		CMAKE_SKIP_TESTS+=( std.math.exponential )
	fi

	cmake_src_test
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

apply_patches() {
	local patches_dir="${WORKDIR}/ldc-patches-${PATCH_TAG_NAME}"
	local patch
	while read -rd '' patch; do
		eapply "${patch}"
	done < <(find "${patches_dir}" -mindepth 1 -maxdepth 1 \
				  -type f -name '*.patch' \
				  -print0)
}
