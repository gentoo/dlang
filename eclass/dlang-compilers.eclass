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
	declare -ga __dlang_dmd_frontend_archmap
	declare -ga __dlang_dmd_frontend_versionmap
	declare -ga __dlang_gdc_frontend_archmap
	declare -ga __dlang_gdc_frontend_versionmap
	declare -ga __dlang_ldc2_frontend_archmap
	declare -ga __dlang_ldc2_frontend_versionmap

	# DMD
	__dlang_dmd_frontend_archmap=(
		[1]="2.063 x86 amd64"
		[2]="2.064 x86 amd64"
		[3]="2.065 x86 amd64"
		[4]="2.066 x86 amd64"
		[5]="2.067 x86 amd64"
		[6]="2.068 x86 amd64"
		[7]="2.069 x86 amd64"
		[8]="2.070 x86 amd64"
		[9]="2.071 x86 amd64"
	)
	__dlang_dmd_frontend_versionmap=(
		[1]="2.063"
		[2]="2.064"
		[3]="2.065"
		[4]="2.066"
		[5]="2.067"
		[6]="2.068"
		[7]="2.069"
		[8]="2.070"
		[9]="2.071"
	)

	# GDC
	__dlang_gdc_frontend_archmap=(
		[1]="2.066 x86 amd64 arm"
	)
	__dlang_gdc_frontend_versionmap=(
		[1]="4.8.5"
	)

	# LDC
	__dlang_ldc2_frontend_archmap=(
		[1]="2.063 x86 amd64"
		[2]="2.064 x86 amd64"
		[3]="2.065 x86 amd64"
		[4]="2.066 x86 amd64"
		[5]="2.067 x86 amd64"
		[6]="2.068 x86 amd64 ~arm ~ppc ~ppc64"
		[7]="2.070 x86 amd64 ~arm ~ppc ~ppc64"
	)
	__dlang_ldc2_frontend_versionmap=(
		[1]="0.12"
		[2]="0.13"
		[3]="0.14"
		[4]="0.15"
		[5]="0.16"
		[6]="0.17"
		[7]="1.0"
	)

	# Error check to avoid mistyping of indices
	if [ "${!__dlang_dmd_frontend_archmap[*]}" \
		!= "${!__dlang_dmd_frontend_versionmap[*]}" ] ; then
		errorstring="__dlang_dmd_frontend_archmap and "
		errorstring+="__dlang_dmd_frontend_versionmap indices mismatch!"
		die $errorstring
	fi
	if [ "${!__dlang_gdc_frontend_archmap[*]}" \
		!= "${!__dlang_gdc_frontend_versionmap[*]}" ] ; then
		errorstring="__dlang_gdc_frontend_archmap and "
		errorstring+="__dlang_gdc_frontend_versionmap indices mismatch!"
		die $errorstring
	fi
	if [ "${!__dlang_ldc2_frontend_archmap[*]}" \
		!= "${!__dlang_ldc2_frontend_versionmap[*]}" ] ; then
		errorstring="__dlang_ldc2_frontend_archmap and "
		errorstring+="__dlang_ldc2_frontend_versionmap indices mismatch!"
		die $errorstring
	fi
}

fi
