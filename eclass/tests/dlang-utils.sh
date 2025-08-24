#!/bin/bash
# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

gentooRepo=$(portageq get_repo_path / gentoo)
readonly gentooRepo


EAPI=8
source "${gentooRepo}"/eclass/tests/tests-common.sh || exit
source "${gentooRepo}"/eclass/tests/version-funcs.sh || exit
TESTS_ECLASS_SEARCH_PATHS=( .. "${gentooRepo}"/eclass )

# Before the inherit so multilib.eclass picks the correct value
export CHOST=x86_my_whatever
inherit dlang-utils

test_var() {
	local var=${1}
	local impl=${2}
	local expect=${3}

	tbegin "${var} for ${impl}"

	local ${var}
	_dlang_export ${impl} ${var}
	# We have variables with [] which breaks [[ == ]]
	[ "${!var}" = "${expect}" ] || eerror "(${impl}: ${var}: '${!var}' != '${expect}'"

	tend ${?}
}

test_is() {
	local func=${1}
	local expect=${2}

	tbegin "${func} (expecting: ${expect})"

	${func}
	[[ ${?} == ${expect} ]]

	tend ${?}
}


test_var EDC dmd-2_102 dmd-2.102
test_var EDC dmd-2.102 dmd-2.102
test_var EDC gdc-13 gdc-13
test_var EDC ldc2-1_35 ldc2-1.35

test_var DC dmd-2_102 "${EPREFIX}"/usr/lib/dmd/2.102/bin/dmd
test_var DC ldc2-1_36 "${EPREFIX}"/usr/lib/ldc2/1.36/bin/ldc2
test_var DC gdc-12 "${EPREFIX}"/usr/"${CHOST_default}"/gcc-bin/12/gdc

test_var DMDW dmd-2.102 "${EPREFIX}"/usr/lib/dmd/2.102/bin/dmd
test_var DMDW ldc2-1.36 "${EPREFIX}"/usr/lib/ldc2/1.36/bin/ldmd2
test_var DMDW gdc-12 "${EPREFIX}"/usr/"${CHOST_default}"/gcc-bin/12/gdmd

# DLANG_LIBDIR tested bellow

test_var DLANG_IMPORT_DIR dmd-2_102 "/usr/include/dlang"
test_var DLANG_IMPORT_DIR gdc-13 "/usr/include/dlang"
test_var DLANG_IMPORT_DIR ldc2-1_35 "/usr/include/dlang"

# DLANG_MODEL_FLAGS tested alongside DLANG_LIBDIR

DMDFLAGS=bar
GDCFLAGS=baz
LDCFLAGS=foo

test_var DCFLAGS dmd-2.102 "bar"
test_var DCFLAGS gdc-13 "baz"
test_var DCFLAGS ldc2-1_36 "foo"

DMDFLAGS='-O'
GDCFLAGS='-march=native'
LDCFLAGS='-flto'

test_var DMDW_DCFLAGS dmd-2.102 "-O"
test_var DMDW_DCFLAGS gdc-13 '-q,-march=native'
test_var DMDW_DCFLAGS ldc2-1_36 "-flto"

LDFLAGS='-Wl,-O1 -Xlinker --as-needed -garbage'
test_var DLANG_LDFLAGS dmd-2.102 "-L-O1 -L--as-needed -garbage"
test_var DLANG_LDFLAGS gdc-13 "${LDFLAGS} -shared-libphobos"
test_var DLANG_LDFLAGS ldc2-1_36  "-L-O1 -L--as-needed -garbage"

# Test multiple flags chained in -Wl,
LDFLAGS='-Wl,-z,pack-relative-relocs -Wl,a,b,c --flto'
test_var DLANG_LDFLAGS dmd-2.106 "-L-z -Lpack-relative-relocs -La -Lb -Lc --flto"
test_var DLANG_LDFLAGS gdc-13 "${LDFLAGS} -shared-libphobos"
test_var DLANG_LDFLAGS ldc2-1_36 "-L-z -Lpack-relative-relocs -La -Lb -Lc --flto"

LDFLAGS='-Wl,-O1 -Xlinker --as-needed -garbage'
test_var DLANG_DMDW_LDFLAGS dmd-2.106 "-L-O1 -L--as-needed -garbage"
test_var DLANG_DMDW_LDFLAGS gdc-13 "-L-O1 -L--as-needed -garbage -q,-shared-libphobos"
test_var DLANG_DMDW_LDFLAGS ldc2-1_35 "-L-O1 -L--as-needed -garbage"

test_var DLANG_DEBUG_FLAG dmd-2.102 "-debug"
test_var DLANG_DEBUG_FLAG gdc-13 "-fdebug"
test_var DLANG_DEBUG_FLAG ldc2-1_36  "-d-debug"

test_var DLANG_LINKER_FLAG dmd-2.102 "-L"
test_var DLANG_LINKER_FLAG gdc-13 "-Wl,"
test_var DLANG_LINKER_FLAG ldc2-1_36  "-L"

test_var DLANG_MAIN_FLAG dmd-2.104 "-main"
test_var DLANG_MAIN_FLAG gdc-15 "-fmain"
test_var DLANG_MAIN_FLAG ldc2-1.40  "-main"

test_var DLANG_OUTPUT_FLAG dmd-2.102 "-of"
test_var DLANG_OUTPUT_FLAG gdc-13 "-o"
test_var DLANG_OUTPUT_FLAG ldc2-1_36  "-of="

test_var DLANG_UNITTEST_FLAG dmd-2.102 "-unittest"
test_var DLANG_UNITTEST_FLAG gdc-13 "-funittest"
test_var DLANG_UNITTEST_FLAG ldc2-1_36  "-unittest"

test_var DLANG_VERSION_FLAG dmd-2.102 "-version"
test_var DLANG_VERSION_FLAG gdc-13 "-fversion"
test_var DLANG_VERSION_FLAG ldc2-1_36  "-d-version"

test_var DLANG_FE_VERSION dmd-2.111 2.111
test_var DLANG_FE_VERSION gdc-13 2.103
test_var DLANG_FE_VERSION ldc2-1_36  2.106

test_var DLANG_BE_VERSION dmd-2.102 2.102
test_var DLANG_BE_VERSION gdc-13 13
test_var DLANG_BE_VERSION ldc2-1_36  1.36

test_var DLANG_WNO_ERROR_FLAG dmd-2.102 -wi
test_var DLANG_WNO_ERROR_FLAG gdc-13 -Wno-error
test_var DLANG_WNO_ERROR_FLAG ldc2-1.36 --wi

test_var DLANG_SYSTEM_IMPORT_PATHS dmd-2.101 "${EPREFIX}/usr/lib/dmd/2.101/import"
test_var DLANG_SYSTEM_IMPORT_PATHS gdc-13 "${EPREFIX}/usr/lib/gcc/${CHOST_default}/13/include/d"
test_var DLANG_SYSTEM_IMPORT_PATHS ldc2-1_32 "${EPREFIX}/usr/lib/ldc2/1.32/include/d"

test_var DLANG_PKG_DEP dmd-2.102 "dev-lang/dmd:2.102="
test_var DLANG_PKG_DEP gdc-12 "sys-devel/gcc:12[d] dev-util/gdmd:0[dlang_targets_gdc-12(-)]"
test_var DLANG_PKG_DEP ldc2-1.36 "dev-lang/ldc2:1.36="
test_var DLANG_PKG_DEP ldc2-1.40 "dev-lang/ldc2:1.40 dev-libs/ldc2-runtime:1.40="

declare -A DLANG_REQ_USE=(
	[dmd]="flag1"
	[gdc]="flag2"
	[ldc2]="flag3(-)?"
)
test_var DLANG_PKG_DEP dmd-2.102 "dev-lang/dmd:2.102=[flag1]"
test_var DLANG_PKG_DEP gdc-12 "sys-devel/gcc:12[d,flag2] dev-util/gdmd:0[dlang_targets_gdc-12(-)]"
test_var DLANG_PKG_DEP ldc2-1.36 "dev-lang/ldc2:1.36=[flag3(-)?]"
test_var DLANG_PKG_DEP ldc2-1.40 "dev-lang/ldc2:1.40 dev-libs/ldc2-runtime:1.40=[flag3(-)?]"

get_libdir() {
	local libdir_var="LIBDIR_${ABI}"
	echo "${!libdir_var}"
}
# multilib
MULTILIB_ABIS="amd64 x86"
DEFAULT_ABI=amd64
LIBDIR_amd64=lib64
LIBDIR_x86=lib

ABI=amd64
test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib64"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/lib64"
test_var DLANG_LIBDIR ldc2-1.40 "lib/ldc2/1.40/lib64"
test_var DLANG_MODEL_FLAG ldc2-1.35 '-m64'
ABI=x86
test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib32"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12/32"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/lib32"
test_var DLANG_LIBDIR ldc2-1.40 "lib/ldc2/1.40/lib"
test_var DLANG_MODEL_FLAG ldc2-1.35 '-m32'

# nomultilib
MULTILIB_ABIS=amd64
DEFAULT_ABI=amd64
LIBDIR_amd64=lib64
ABI=amd64
test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib64"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/lib64"
test_var DLANG_LIBDIR ldc2-1.40 "lib/ldc2/1.40/lib64"
test_var DLANG_MODEL_FLAG ldc2-1.35 ''
LIBDIR_amd64=mylib
test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib64"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/mylib"
test_var DLANG_LIBDIR ldc2-1.40 "lib/ldc2/1.40/mylib"

MULTILIB_ABIS=x86
DEFAULT_ABI=x86
LIBDIR_x86=lib
ABI=x86
test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/lib"
test_var DLANG_MODEL_FLAG ldc2-1.35 ''
LIBDIR_x86=mylib
test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/mylib"

MULTILIB_ABIS=arm64
DEFAULT_ABI=arm64
LIBDIR_arm64=lib64
ABI=arm64
#test_var DLANG_LIBDIR dmd-2.102 "lib/dmd/2.102/lib64"
test_var DLANG_LIBDIR gdc-12 "lib/gcc/${CHOST_default}/12"
test_var DLANG_LIBDIR ldc2-1.35 "lib/ldc2/1.35/lib64"
test_var DLANG_MODEL_FLAG ldc2-1.35 ''

assert_eq() {
	local what=${1} expected=${2}

	[[ ${what} != ${expected} ]] && die "'${what}' != '${expected}'"
}

# No $EDC set
assert_eq $(EDC= dlang_get_import_dir) "/usr/include/dlang"

tbegin '_dlang_compile_extra_flags'

imports="A B"
assert_eq "$(EDC=dmd-2.102 _dlang_compile_extra_flags)" "-IA -IB"
string_imports="c d"
assert_eq "$(EDC=dmd-2.102 _dlang_compile_extra_flags)" "-IA -IB -Jc -Jd"
versions="x yY"
assert_eq "$(EDC=dmd-2.102 _dlang_compile_extra_flags)" \
		  "-IA -IB -Jc -Jd -version=x -version=yY"
libs="bar baz"
assert_eq "$(EDC=dmd-2.102 _dlang_compile_extra_flags)" \
		  "-IA -IB -Jc -Jd -version=x -version=yY -L-lbar -L-lbaz"
assert_eq "$(EDC=gdc-12 _dlang_compile_extra_flags)" \
		  "-IA -IB -Jc -Jd -fversion=x -fversion=yY -Wl,-lbar -Wl,-lbaz"
assert_eq "$(EDC=ldc2-1.35 _dlang_compile_extra_flags)" \
		  "-I=A -I=B -J=c -J=d -d-version=x -d-version=yY -L-lbar -L-lbaz"
tend


tbegin "that _dlang_verify_patterns accepts frontend versions"
( _dlang_verify_patterns "2.100" "2.107" )
tend ${?}

tbegin "_dlang_impl_matches on frontend version"
_dlang_impl_matches "gdc-13" "2.103"
tend ${?}

# check _dlang_impl_matches behavior
einfo "Testing dlang_impl_matches"
eindent
test_is "_dlang_impl_matches gdc-13 2.103" 0
test_is "_dlang_impl_matches dmd-2_107 2.107" 0
test_is "_dlang_impl_matches ldc2-1_36 2.106" 0
set -f
test_is "_dlang_impl_matches gdc-13 gdc*" 0
test_is "_dlang_impl_matches dmd-2.110 gdc*" 1
test_is "_dlang_impl_matches gdc-13 dmd-2_103" 1
test_is "_dlang_impl_matches dmd-2.107 dmd-2.0*" 1
test_is "_dlang_impl_matches ldc2-1_40 ldc2*" 0
set +f
test_is "_dlang_impl_matches gdc-12 2.100" 0
test_is "_dlang_impl_matches gdc-12 2.086" 1
test_is "_dlang_impl_matches gdc-12 2.103" 1
test_is "_dlang_impl_matches dmd-2_107 2.107" 0
test_is "_dlang_impl_matches dmd-2_107 2.106" 1
test_is "_dlang_impl_matches dmd-2_107 2.103" 1
test_is "_dlang_impl_matches ldc2-1_36 2.107" 1
test_is "_dlang_impl_matches ldc2-1_36 2.103" 1

# Check for the oldest frontend version patterns
test_is "_dlang_impl_matches gdc-12 2.100" 0
test_is "_dlang_impl_matches dmd-2.107 2.107" 0
test_is "_dlang_impl_matches ldc2-1.36 2.106" 0
eoutdent

tbegin "simple dlang-filter-dflags"
EDC=dmd-2.105
DMDFLAGS='-O --color -mcpu=native'
dlang-filter-dflags "dmd*" "--col*"
[[ "${DMDFLAGS}" == "-O -mcpu=native" ]]
tend $?

tbegin "propagation of flag changes done by dlang-filter-dflags"
EDC=gdc-12
GDCFLAGS='-march=native -O2 -pipe'
_dlang_export "${EDC}" DCFLAGS DMDW_DCFLAGS
dlang-filter-dflags "gdc*" "-march=native"
[[ "${GDCFLAGS}" == "-O2 -pipe" ]] &&
	[[ "${DCFLAGS}" == "-O2 -pipe" ]] &&
	[[ "${DMDW_DCFLAGS}" == "-q,-O2 -q,-pipe" ]]
tend $?

tbegin "dlang_get_abi_bits"
assert_eq $(dlang_get_abi_bits x86) 32
assert_eq $(dlang_get_abi_bits amd64) 64
assert_eq $(dlang_get_abi_bits aarch64) ""
assert_eq $(ABI=x86 dlang_get_abi_bits) 32
tend
