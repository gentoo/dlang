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
	)

	# GDC (alpha, hppa, sparc: masked "d" USE-flag)
	__dlang_gdc_frontend=(
		["6.4.0"]="2.068 alpha amd64 arm arm64 hppa ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd"
		["7.3.0"]="2.081 alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~ppc-macos"
	)

	# LDC
	__dlang_ldc2_frontend=(
		["0.17"]="2.068 amd64 ~arm x86"
		["1.4"]="2.074 amd64 ~arm x86"
		["1.5"]="2.075 amd64 ~arm x86"
		["1.6"]="2.076 amd64 ~arm x86"
		["1.7"]="2.077 amd64 ~arm x86"
		["1.8"]="2.078 amd64 ~arm x86"
		["1.9"]="2.079 amd64 ~arm x86"
		["1.10"]="2.080 amd64 ~arm x86"
		["1.11"]="2.081 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.12"]="2.082 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.13"]="2.083 amd64 ~arm ~arm64 ~ppc64 x86"
		["1.14"]="2.083 amd64 ~arm ~arm64 ~ppc64 x86"
	)
}

fi
