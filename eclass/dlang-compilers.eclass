# @ECLASS: dlang-compilers.eclass
# @MAINTAINER:
# Marco Leise <marco.leise@gmx.de>
# @BLURB: Support data for dlang.eclass
# @DESCRIPTION:
# Contains the available D compiler versions with their stable archs.

if [[ ${_ECLASS_ONCE_DLANG_COMPILERS} != "recur -_+^+_- spank" ]] ; then
_ECLASS_ONCE_DLANG_COMPILERS="recur -_+^+_- spank"

# @FUNCTION: dlang-compilers_declare_versions
# @DESCRIPTION:
# Exports an associative array of all available Dlang compiler versions and their corresponding language support as well
# as the list of stable and unstable keywords. The language support is basically the DMD front-end version that the
# compiler is based on. For DMD it will be the same as the compiler version, while for GDC and LDC2 it will differ.
# The keywords are required, because we offer many compilers to be used for Dlang packages and pull them in as build
# time dependencies. A stable package cannot depend on an unstable package though, so short of manually looking for
# KEYWORDS in compiler ebuilds we just keep them up-to-date here. GDC in particular needs constant attention as
# architectures get markes stable all the time.
dlang-compilers_declare_versions() {
	declare -gA _dlang_dmd_frontend
	declare -gA _dlang_gdc_frontend
	declare -gA _dlang_ldc2_frontend

	# DMD
	_dlang_dmd_frontend=(
		["2.107"]="2.107 ~x86 ~amd64"
	)

	# GDC (hppa, sparc: masked "d" USE-flag)
	_dlang_gdc_frontend=(
		["11"]="2.076 ~alpha amd64 arm arm64 ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 x86"
		["12"]="2.100 ~alpha amd64 arm arm64 ~ia64 ~m68k ~mips ~ppc ppc64 ~riscv ~s390 x86"
		["13"]="2.103 ~alpha amd64 arm arm64 ~ia64 ~loong ~m68k ~mips ~ppc ppc64 ~riscv ~s390 x86"
	)

	# LDC
	_dlang_ldc2_frontend=(
		["1.36"]="2.106 ~amd64 ~arm64 ~x86"
	)
}

fi
