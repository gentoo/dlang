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
		["2.064"]="2.064 x86 amd64"
		["2.065"]="2.065 x86 amd64"
		["2.066"]="2.066 x86 amd64"
		["2.067"]="2.067 x86 amd64"
		["2.068"]="2.068 x86 amd64"
		["2.069"]="2.069 x86 amd64"
		["2.070"]="2.070 x86 amd64"
		["2.071"]="2.071 x86 amd64"
		["2.072"]="2.072 x86 amd64"
		["2.073"]="2.073 x86 amd64"
		["2.074"]="2.074 x86 amd64"
		["2.075"]="2.075 x86 amd64"
		["2.076"]="2.076 x86 amd64"
		["2.077"]="2.077 x86 amd64"
		["2.078"]="2.078 x86 amd64"
		["2.079"]="2.079 x86 amd64"
		["2.080"]="2.080 x86 amd64"
		["2.081"]="2.081 x86 amd64"
		["2.082"]="2.082 x86 amd64"
		["2.083"]="2.083 x86 amd64"
		["2.084"]="2.084 x86 amd64"
		["2.085"]="2.085 x86 amd64"
		["2.086"]="2.086 x86 amd64"
		["2.087"]="2.087 x86 amd64"
		["2.088"]="2.088 x86 amd64"
		["2.089"]="2.089 x86 amd64"
		["2.090"]="2.090 x86 amd64"
		["2.091"]="2.091 x86 amd64"
		["2.092"]="2.092 x86 amd64"
		["2.093"]="2.093 x86 amd64"
		["2.094"]="2.094 x86 amd64"
		["2.095"]="2.095 x86 amd64"
		["2.096"]="2.096 x86 amd64"
		["2.097"]="2.097 x86 amd64"
		["2.098"]="2.098 x86 amd64"
		["2.099"]="2.099 x86 amd64"
		["2.100"]="2.100 ~x86 ~amd64"
		["2.101"]="2.101 ~x86 ~amd64"
		["2.102"]="2.102 ~x86 ~amd64"
		["2.103"]="2.103 ~x86 ~amd64"
	)

	# GDC (hppa, sparc: masked "d" USE-flag)
	_dlang_gdc_frontend=(
		["11.3.1_p20230427"]="2.076 ~alpha amd64 arm arm64 ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 x86"
		["11.4.0"]="2.076 ~alpha ~amd64 ~arm ~arm64 ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~x86"
		["11.4.1_p20230622"]="2.076 ~alpha ~amd64 ~arm ~arm64 ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 x86"
		["12.2.1_p20230428"]="2.100 ~alpha amd64 arm arm64 ~ia64 ~m68k ~mips ~ppc ppc64 ~riscv ~s390 x86"
		["12.3.1_p20230526"]="2.100 ~alpha amd64 arm arm64 ~ia64 ~m68k ~mips ~ppc ppc64 ~riscv ~s390 x86"
		["12.3.1_p20230623"]="2.100 ~alpha ~amd64 ~arm ~arm64 ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~x86"
		["13.1.1_p20230527"]="2.103 ~alpha ~amd64 ~arm ~arm64 ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~x86"
		["13.2.0"]="2.103 ~alpha ~amd64 ~arm ~arm64 ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~x86"
	)

	# LDC
	_dlang_ldc2_frontend=(
		["1.29"]="2.099 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.30"]="2.100 ~amd64 ~arm ~arm64 ~ppc64 ~x86"
	)
}

fi
