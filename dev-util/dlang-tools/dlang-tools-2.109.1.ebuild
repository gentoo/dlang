# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Ancilliary tools for the D programming language compiler"
HOMEPAGE="http://dlang.org/"

DLANG_SLOT="$(ver_cut 1-2)"

BETA="$(ver_cut 4)"
VERSION="$(ver_cut 1-3)"

if [[ -n "${BETA}" ]]; then
	# We want to convert a Gentoo version string into an upstream one: 2.097.0_rc1 -> 2.097.0-rc.1
	VERSION="$(ver_rs 3 "-" 4 ".")"
fi
SRC_URI="https://codeload.github.com/dlang/tools/tar.gz/v${VERSION} -> dlang-tools-${VERSION}.tar.gz"
S="${WORKDIR}/tools-${VERSION}"

LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~x86"

TOOLS="ddemangle detab dustmite rdmd"
IUSE="+ddemangle detab dustmite +rdmd test"
RESTRICT="!test? ( test )"

DLANG_COMPAT=( dmd-2_{106..109} gdc-1{3,4} ldc2-1_{35..40} )

inherit desktop dlang-single xdg-utils

PATCHES=(
	# The make tests fails due to https://savannah.gnu.org/bugs/?65588
	"${FILESDIR}/2.108.0-rdmd-disable-make-test.patch"
	"${FILESDIR}/gdc-13-fix-parentheses.patch"
)

REQUIRED_USE="|| ( ${TOOLS[@]} ) ${DLANG_REQUIRED_USE} test? ( || ( ddemangle dustmite rdmd ) )"
DEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}

src_compile() {
	use ddemangle && dlang_compile_bin ddemangle ddemangle.d
	use detab     && dlang_compile_bin detab     detab.d
	use dustmite  && dlang_compile_bin dustmite  DustMite/dustmite.d DustMite/splitter.d DustMite/polyhash.d
	use rdmd      && dlang_compile_bin rdmd      rdmd.d
}

src_test() {
	if use ddemangle; then
		dlang_compile_bin ddemangle_ut ddemangle.d $(dlang_get_unittest_flag)
		./ddemangle_ut || die 'ddemangle unittests failed'
	fi
	if use dustmite; then
		dlang_compile_bin dustmite_ut DustMite/dustmite.d DustMite/splitter.d DustMite/polyhash.d $(dlang_get_unittest_flag)
		./dustmite_ut || die 'dustmite unittests failed'
	fi
	if use rdmd; then
		# Add an empty main since gdc doesn't support -main
		echo 'void main(){}' >> rdmd.d
		dlang_compile_bin rdmd_ut rdmd.d $(dlang_get_unittest_flag)
		./rdmd_ut || die 'rdmd unittests failed'

		# These tests fail with gdc, due to some quirks.
		#
		# On aarch64, -m64 is not supported by gdc.
		# See: https://github.com/dlang/tools/pull/470
		#
		# On other arches there is one test failing. See:
		# https://github.com/dlang/tools/pull/469 for possible
		# solutions.
		#
		# These issues have existed for a while so ignore the failures.
		if [[ ${EDC} == gdc* ]]; then
			ewarn "Some rdmd tests have been skipped"
		else
			dlang_compile_bin rdmd_test rdmd_test.d
			local model
			# Note that dlang_get_model_flag doesn't work here since it
			# is only meant for multilib.
			[[ ${ABI} == @(x86|amd64) ]] && model=-m$(dlang_get_abi_bits)
			# One test uses make, it can be specified through $MAKE if needed.
			./rdmd_test -v \
						${model} \
						--rdmd-default-compiler="$(dlang_get_dmdw)" \
						./rdmd || die 'rdmd tests failed'
		fi

	fi
}

src_install() {
	for tool in ${TOOLS}; do
		if use "${tool}"; then
			dobin "${tool}"
		fi
	done

	# file icons
	for size in 16 22 24 32 48 256; do
		newicon --size "${size}" --context mimetypes "${FILESDIR}/icons/${size}/dmd-source.png" text-x-dsrc.png
	done
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
