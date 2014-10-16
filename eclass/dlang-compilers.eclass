# @ECLASS: dlang-compilers.eclass
# @MAINTAINER: marco.leise@gmx.de
# @BLURB:
# Support data for dlang.eclass
# @DESCRIPTION:
# Contains the available D compiler versions with their stable archs.

if [[ ${___ECLASS_ONCE_DLANG_COMPILERS} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_DLANG_COMPILERS="recur -_+^+_- spank"

EXPORT_FUNCTIONS declare_versions

dlang-compilers_declare_versions() {
	declare -gA __dlang_dmd_frontend_mapping
	declare -gA __dlang_gdc_frontend_mapping
	declare -gA __dlang_ldc2_frontend_mapping

	# DMD
	__dlang_dmd_frontend_mapping=(
		["2.063"]="2.063 x86 amd64"
		["2.064"]="2.064 x86 amd64"
		["2.065"]="2.065 x86 amd64"
		["2.066"]="2.066"
	)

	# GDC
	__dlang_gdc_frontend_mapping=(
		["4.8.1"]="2.063"
		["4.8.2"]="2.064"
		["4.8.3"]="2.065"
	)

	# LDC
	__dlang_ldc2_frontend_mapping=(
		["0.12"]="2.063 x86 amd64"
		["0.13"]="2.064 x86 amd64"
		["0.14"]="2.065 x86 amd64"
	)
}

fi