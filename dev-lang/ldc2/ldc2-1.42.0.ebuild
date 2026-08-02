# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( dmd-2_{107..111} gdc-1{3..5} ldc2-1_{36..40} ldc2-1_42 )
LLVM_COMPAT=( {17..21} )
PYTHON_COMPAT=( python3_{12..14} )
inherit dlang-single llvm-r2 multiprocessing python-any-r1 toolchain-funcs cmake

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
# dmd code but without the runtime libs, see dmd-r1.eclass for more details
LICENSE+=" Boost-1.0 || ( CC0-1.0 Apache-2.0 )"
# llvm bits
LICENSE+=" Apache-2.0-with-LLVM-exceptions UoI-NCSA"
# old gdc + dmd code
LICENSE+=" GPL-2+ Artistic"

SLOT="$(ver_cut 1-2)"
KEYWORDS="~amd64 ~arm64 ~x86"

IUSE="debug test"
RESTRICT="!test? ( test )"

REQUIRED_USE=${DLANG_REQUIRED_USE}
COMMON_DEPEND="
	${DLANG_DEPS}
	$(llvm_gen_dep '
	  llvm-core/llvm:${LLVM_SLOT}=[debug=]
	')
"
RDEPEND="${COMMON_DEPEND}"
DEPEND="
	${COMMON_DEPEND}
	test? (
		  dev-libs/ldc2-runtime:${SLOT}
	)
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
IDEPEND=">=app-eselect/eselect-dlang-20241230"
PDEPEND="dev-libs/ldc2-runtime:${SLOT}"

INSTALL_PREFIX="${EPREFIX}/usr/lib/ldc2/${SLOT}" # /usr/lib/ldc2/1.40

python_check_deps() {
	python_has_version "dev-python/lit[${PYTHON_USEDEP}]"
}

pkg_setup() {
	dlang_setup
	llvm-r2_pkg_setup
	use test && python_setup
}

src_prepare() {
	# Disable GDB tests by passing GDB_FLAGS=OFF
	# Put this here to avoid trigerring reconfigurations later on.
	sed -i 's/\(GDB_FLAGS=\)\S\+/\1OFF/' "${S}"/tests/dmd/CMakeLists.txt || die

	# Calls gcc directly
	sed -i "s/gcc/$(tc-getCC)/" "${S}"/tests/dmd/runnable/importc-test1.sh || die

	apply_patches

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DLDC_ENABLE_ASSERTIONS=$(usex debug ON OFF)
		-DD_COMPILER="$(dlang_get_dmdw) $(dlang_get_dmdw_dcflags)"
		-DCOMPILER_RT_BASE_DIR="${EPREFIX}"/usr/lib/clang
		-DCOMPILER_RT_LIBDIR_OS=linux
		# TODO: enable this
		-DLDC_DYNAMIC_COMPILE=OFF

		-DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"
		-DPHOBOS_SYSTEM_ZLIB=ON
		-DLDC_BUILD_RUNTIME=OFF
		-DLDC_WITH_LLD=OFF
		-DLDC_BUNDLE_LLVM_TOOLS=OFF
		-DCOMPILE_D_MODULES_SEPARATELY=ON
		-DTEST_COMPILER_RT_LIBRARIES=none
		-DRT_SUPPORT_SANITIZERS=False
		# Avoid collisions with other slots. We hardcode the path to
		# make it easier for eselect-dlang to find the right compdir.
		-DBASH_COMPLETION_COMPLETIONSDIR="${INSTALL_PREFIX}/usr/share/bash-completion/completions"
	)
	if use test; then
		mycmakeargs+=(
			-DGNU_MAKE_BIN="gmake" # tests/plugins/addFuncEntryCall/testPlugin.d
			-DRUNTIME_DIR="${S}/runtime/druntime"
		)
	fi
	cmake_src_configure
}

src_test() {
	make_conf_file

	# Call the same tests that .github/actions/main.yml does
	local jobs=$(get_makeopts_jobs)

	# We build it explicitly so that MAKEOPTS is respected
	cmake_src_compile ldc2-unittest
	cmake_src_test -R ldc2-unittest

	# Instead of running cmake_src_test -R lit-tests we call lit directly
	pushd "${BUILD_DIR}"/tests > /dev/null || die
	"${EPYTHON}" runlit.py -j${jobs} -v . || die 'lit tests failed'
	popd > /dev/null || die

	# The dmd testsuite comes into debug and release variants. The debug
	# one does compilable + fail_compilation + runnable, release only
	# does runnable. Since it's a compiler I think it's fine to allow
	# the duplicate tests. A few compilable tests fail with -O.
	#
	# These tests invoke a runner that runs the tests in parallel so
	# specify the jobs only to the runner and not cmake. I'm pretty sure
	# that some of the tests can't be run simultaneously by multiple
	# runners so keep the cmake jobs to 1.
	DMD_TESTSUITE_MAKE_ARGS=-j${jobs} cmake_src_test -j 1 -V -R dmd-testsuite
}

src_install() {
	cmake_src_install

	cat <<EOF > "${D}/${INSTALL_PREFIX}/etc/ldc2.conf/40-gentoo.conf" || die
default: {
	switches ~= [
		"-link-defaultlib-shared",
	];
}
EOF

	local ldc2_root="${INSTALL_PREFIX#${EPREFIX}}"
	dosym -r "${ldc2_root}/bin/ldc2" "/usr/bin/ldc2-${SLOT}"
	dosym -r "${ldc2_root}/bin/ldmd2" "/usr/bin/ldmd2-${SLOT}"
	dosym -r "${ldc2_root}/etc/ldc2.conf" "/etc/ldc2/${SLOT}"
}

pkg_postinst() {
	"${EROOT}"/usr/bin/eselect dlang update ldc2
}

pkg_postrm() {
	"${EROOT}"/usr/bin/eselect dlang update ldc2
}

apply_patches() {
	local patches_dir="${WORKDIR}/ldc-patches-${PATCH_TAG_NAME}"
	local patch
	einfo "Applying patches from: ${patches_dir}"
	while read -rd '' patch; do
		eapply "${patch}"
	done < <(find "${patches_dir}" -mindepth 1 -maxdepth 2 \
				  -type f -name '*.patch' \
				  -print0)
}

# Generate a ldc2.conf file that uses the installed ldc2-runtime and the built headers
make_conf_file() {
	local conf_dir="${BUILD_DIR}/etc/ldc2.conf"
	local conf="${conf_dir}/50-target-default.conf"

	mkdir -p "${conf_dir}" || die
	local libdir="${ESYSROOT}/usr/$(dlang_get_libdir ${PN}-${SLOT})"
	cat > "${conf}" <<-EOF || die
	default: {
		switches ~= [
			"-link-defaultlib-shared",
		];
		post-switches = [
			"-I${S}/runtime/druntime/src",
			"-I${BUILD_DIR}/import",
			"-I${S}/runtime/jit-rt/d",
			"-I${S}/runtime/phobos",
		];
		lib-dirs = [
			"${libdir}",
		];
		rpath = "${libdir}";
	}
	EOF
}
