# @ECLASS: dlang-compilers.eclass
# @MAINTAINER: marco.leise@gmx.de
# @BLURB: Support data for dlang.eclass
# @DESCRIPTION:
# Contains the available D compiler versions with their stable archs.

if [[ ${___ECLASS_ONCE_DLANG_COMPILERS} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_DLANG_COMPILERS="recur -_+^+_- spank"

dlang-compilers_declare_versions() {
	declare -gA __dlang_dmd_frontend
	declare -gA __dlang_gdc_frontend
	declare -gA __dlang_ldc2_frontend

	# DMD
	__dlang_dmd_frontend=(
		["2.063"]="2.063 x86 amd64"
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
	)

	# GDC (hppa, sparc: masked "d" USE-flag)
	__dlang_gdc_frontend=(
		["9.3.0"]="2.076 amd64 arm arm64 ~ia64 ~m68k ~mips ppc ppc64 ~riscv s390 x86"
	)

	# LDC
	__dlang_ldc2_frontend=(
		["1.20"]="2.090 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.21"]="2.091 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.22"]="2.092 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.23"]="2.093 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.24"]="2.094 amd64 ~arm ~arm64 ~ppc64 x86"
	)
}

fi
