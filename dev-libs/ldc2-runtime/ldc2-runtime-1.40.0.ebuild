# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( ldc2-1_$(ver_cut 2) )
inherit dlang-single multilib cmake-multilib

PATCH_VER=1
PATCH_TAG_NAME="${PV}-patches-${PATCH_VER}"
PATCH_URL_BASE="https://github.com/the-horo/ldc-patches/archive/refs/tags"

DESCRIPTION="LLVM D Compiler"
HOMEPAGE="https://github.com/ldc-developers/ldc"
MY_PV="${PV//_/-}"
MY_P="ldc-${MY_PV}-src"
SRC_URI="
	https://github.com/ldc-developers/ldc/releases/download/v${MY_PV}/${MY_P}.tar.gz
	${PATCH_URL_BASE}/${PATCH_TAG_NAME}.tar.gz -> ldc2-${PV}-patches-${PATCH_VER}.tar.gz
"
S=${WORKDIR}/${MY_P}
LICENSE="BSD"
# runtime libs, see dmd-r1.eclass for more details
LICENSE+=" Boost-1.0 BZIP2 ZLIB curl public-domain"

# Only increase subslot in case of ABI breakage
SLOT="$(ver_cut 1-2)/0"
LDC2_SLOT="$(ver_cut 1-2)" # SLOT without subslot
KEYWORDS="~amd64 ~x86"

IUSE="static-libs test"
RESTRICT="!test? ( test )"

REQUIRED_USE=${DLANG_REQUIRED_USE}
RDEPEND="
	sys-libs/zlib:0/1
	net-misc/curl[${MULTILIB_USEDEP}]
"
# curl is dlopened. The tests do need it though.
DEPEND="
	sys-libs/zlib:0/1
	test? (
		  net-misc/curl[${MULTILIB_USEDEP}]
	)
"
# We purposefully ignore DLANG_DEPS, we only need the ldc2 compiler and only in BROOT
BDEPEND="dev-lang/ldc2:${LDC2_SLOT}"
IDEPEND=">=app-eselect/eselect-dlang-20241230"

INSTALL_PREFIX="${EPREFIX}/usr/lib/ldc2/${LDC2_SLOT}" # /usr/lib/ldc2/1.40
STRING_IMPORTS_DIR="${T}/views"
LDC2_CONF_DIR="${WORKDIR}/conf"

src_prepare() {
	mkdir -p "${STRING_IMPORTS_DIR}" || die
	local tzpath="${STRING_IMPORTS_DIR}/TZDatabaseDirFile"
	# std.datetime.timezone default search path, instead of /usr/share/zoneinfo/
	echo "${EPREFIX}/usr/share/zoneinfo/" > "${tzpath}" || die

	# Create wrappers for ldc2 because the cmake file only supports
	# passing arguments to the compiler at the end of the command line.
	# This breaks the -conf= argument that we want to use.
	cat <<-EOF > "${T}/ldc2" || die
	#!/bin/sh
	exec "${DC}" -conf="${LDC2_CONF_DIR}/ldc2.conf" "\${@}"
	EOF
	cat <<-EOF > "${T}/ldmd2" || die
	#!/bin/sh
	exec "$(dlang_get_dmdw)" -conf="${LDC2_CONF_DIR}/ldc2.conf" "\${@}"
	EOF
	chmod +x "${T}/ldc2" "${T}/ldmd2" || die

	apply_patches

	cmake_src_prepare
}

src_configure() {
	add_multilib_sections() {
		multilib_is_native_abi && return
		add_multilib_section "${S}/ldc2_phobos.conf.in" "${BUILD_DIR}/$(get_libdir)"
		add_multilib_section "${S}/ldc2_install.conf.in" "${INSTALL_PREFIX}/$(get_libdir)"
	}
	multilib_foreach_abi add_multilib_sections

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=$(usex static-libs BOTH ON)
		# flags for the runtime, the need to be separated by ;
		-DD_FLAGS_RELEASE="${DCFLAGS// /;}"
		# Slight improvements with this
		-DCOMPILE_ALL_D_FILES_AT_ONCE=OFF

		-DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"
		-DPHOBOS_SYSTEM_ZLIB=ON
		-DLDC_EXE_FULL="${T}/ldc2"
		-DLDMD_EXE_FULL="${T}/ldmd2"
		# needed for the sake of EPREFIX
		-DPHOBOS2_EXTRA_FLAGS="-J;${STRING_IMPORTS_DIR};-d-version=TZDatabaseDir"
		# ${EDC}                   # ldc2-1.40
		#   .dlang_get_fe_version  # 2.110
		#   .ver_cut(2)            # 110
		-DDMDFE_MINOR_VERSION="$(ver_cut 2 $(dlang_get_fe_version ${EDC}))"
		-DDMDFE_PATCH_VERSION="$(ver_cut 3)"
	)
	if ! multilib_is_native_abi; then
		# configure multilib flags
		mycmakeargs+=(
			-DD_EXTRA_FLAGS="$(dlang_get_model_flag)"
			-DRT_CFLAGS="$(get_abi_CFLAGS)"
		)
	else
		# we save the config file from the native build
		mycmakeargs+=(-DCONFIG_FILE_OUTPUT_DIR="${LDC2_CONF_DIR}")
	fi

	CMAKE_USE_DIR="${S}/runtime" cmake_src_configure
}

multilib_src_test() {
	# cmake.eclass modifies this internally but doesn't declare it as local making
	# changes to it carry out across invocations of ${FUNCNAME}
	local myctestargs

	# We compile the tests first so that $MAKEOPTS is respect, if
	# compiled during the tests, nproc jobs will be used.
	cmake_src_compile all-test-runners

	local CMAKE_SKIP_TESTS=(
		# These require valgrind
		druntime-test-gc
		druntime-test-valgrind
		# Should be fixed by https://github.com/dlang/dmd/pull/16851
		# Drop the above once the changes are merged into ldc2

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

	# This test requires "${TEMP}/<some-file>" to be less than 108 characters.
	# We will run it separately and force ${TEMP} to be a shorter path.
	TMPDIR="." cmake_src_test -R std.socket
	CMAKE_SKIP_TESTS+=( std.socket )

	# We don't want to run gdb or valgrind tests
	local -x GDB=gdb-dont-find-me VALGRIND=valgrind-dont-find-me
	cmake_src_test
}

multilib_src_compile() {
	cmake_src_compile
	symlinks_release_runtime_to_debug "${BUILD_DIR}"
}

multilib_src_install() {
	cmake_src_install
	symlinks_release_runtime_to_debug "${D}/${INSTALL_PREFIX}"
}

multilib_src_install_all() {
	local ldc2_etc="${INSTALL_PREFIX#"${EPREFIX}"}/etc"
	insinto "${ldc2_etc}"
	newins "${LDC2_CONF_DIR}"/ldc2_install.conf ldc2.conf
	dosym -r "${ldc2_etc}"/ldc2.conf "/etc/ldc2/${LDC2_SLOT}.conf"
}

pkg_postinst() {
	"${EROOT}"/usr/bin/eselect dlang update ldc2
}

pkg_postrm() {
	"${EROOT}"/usr/bin/eselect dlang update ldc2
}

apply_patches() {
	local patches_dir="${WORKDIR}/ldc-patches-${PATCH_TAG_NAME}/runtime"
	einfo "Applying patches from: ${patches_dir}"
	local patch
	while read -rd '' patch; do
		eapply "${patch}"
	done < <(find "${patches_dir}" -mindepth 1 -maxdepth 1 \
				  -type f -name '*.patch' \
				  -print0)
}

# Create symlinks to libdruntime-ldc-shared et al from libdruntime-ldc-debug-shared
# Usage: <dir>
# The symlinks are made in <dir>/$(get_libdir)
symlinks_release_runtime_to_debug() {
	rename_in_dir() {
		local file find_cmd=(
			find "${1}" -mindepth 1 -maxdepth 1
			# Find files that look like a runtime library
			-regex ".*/lib\(druntime\|phobos\)[^/]*"
			# and are not a debug variant
			-not -name '*debug*'
			-printf '%f\0'
		)
		while read -rd '' file; do
			# and symlink them:
			# ${file}                 == libdruntime-ldc-shared
			# ${file/-ldc/-ldc-debug} == libdruntime-ldc-debug-shared
			ln -s "${file}" "${1}/${file/-ldc/-ldc-debug}" || die
		done < <("${find_cmd[@]}")
	}

	rename_in_dir "${1}/$(get_libdir)"
}

# USAGE: <ldc2_conf_file> <full_libdir>
add_multilib_section() {
	# NOTE: We're missing compiler-rt's libdir
	local filepath=${1} libdir=${2}
	local triple_without_vendor=$(sed -e 's/-[^-]*/-.*/' <<<"${CHOST}") # i686-.*-linux-gnu
	cat >> "${filepath}" <<EOF || die "Could not add multilib section"

"${triple_without_vendor}":
{
	lib-dirs = [
		"${libdir}",
	];
	rpath = "${libdir}";
};
EOF
}
