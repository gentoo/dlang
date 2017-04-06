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
	declare -g __dlang_archs="alpha amd64 amd64-fbsd amd64-linux arm arm-linux arm64 hppa ia64 m68k m68k-mint mips nios2 ppc ppc64 ppc64-linux ppc-aix ppc-macos riscv s390 sh sparc sparc64-solaris sparc-fbsd sparc-solaris x64-cygwin x64-macos x64-solaris x86 x86-cygwin x86-fbsd x86-linux x86-macos x86-solaris x86-winnt"

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
		["2.073"]="2.073 ~x86 ~amd64"
	)

	# GDC (alpha, hppa, sparc: masked "d" USE-flag)
	__dlang_gdc_frontend=(
		["4.8.5"]="2.066 x86 amd64 arm"
		["4.9.4"]="2.068 ~amd64 ~arm arm64 ~ia64 m68k ~mips ~ppc ~ppc64 s390 sh ~x86 ~amd64-fbsd ~x86-fbsd"
	)

	# LDC
	__dlang_ldc2_frontend=(
		["0.14"]="2.065 ~x86 ~amd64"
		["0.15"]="2.066 ~x86 ~amd64"
		["0.16"]="2.067 x86 amd64"
		["0.17"]="2.068 x86 amd64 ~arm"
		["1.0"]="2.070 x86 amd64 ~arm"
		["1.1"]="2.071 ~x86 ~amd64 ~arm"
	)
}

fi
