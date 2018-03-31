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
		["2.079"]="2.079 ~x86 ~amd64"
	)

	# GDC (alpha, hppa, sparc: masked "d" USE-flag)
	__dlang_gdc_frontend=(
		["6.4.0"]="2.068 amd64 arm hppa ia64 m68k ppc ppc64 s390 sh x86 ~amd64-fbsd ~x86-fbsd"
	)

	# LDC
	__dlang_ldc2_frontend=(
		["0.17"]="2.068 x86 amd64 ~arm"
		["1.1"]="2.071 x86 amd64 ~arm"
		["1.2"]="2.072 x86 amd64 ~arm"
		["1.3"]="2.073 x86 amd64 ~arm"
		["1.4"]="2.074 x86 amd64 ~arm"
		["1.5"]="2.075 x86 amd64 ~arm"
		["1.6"]="2.076 x86 amd64 ~arm"
		["1.7"]="2.077 x86 amd64 ~arm"
		["1.8"]="2.078 ~x86 ~amd64 ~arm"
	)
}

fi
