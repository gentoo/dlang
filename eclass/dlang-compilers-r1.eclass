# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dlang-compilers-r1.eclass
# @MAINTAINER:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# @AUTHOR:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# Based on dlang-compilers.eclass by Marco Leise <marco.leise@gmx.de>.
# @BUGREPORTS:
# Please report bugs via https://github.com/gentoo/dlang/issues
# @VCSURL: https://github.com/gentoo/dlang
# @BLURB: Support data for dlang-utils.eclass
# @DESCRIPTION:
# Contains the available D compiler and the language version they
# support.

if [[ ! ${_DLANG_COMPILERS_R1_ECLASS} ]] ; then
_DLANG_COMPILERS_R1_ECLASS=1

# @ECLASS_VARIABLE: _DLANG_DMD_FRONTENDS
# @INTERNAL
# @DESCRIPTION:
# A list of dmd implementations with their dlang frontend version (which
# happens to coincide with the implementation version)
#
# The elements are ordered, the higher implementation version has the
# higher index.
#
# Example value for an element:
# @CODE
# "2.102 2.102"
# @CODE
# Where the first 2.102 represents the implementation version and the
# second one represents the D language version the implementation
# supports.
readonly _DLANG_DMD_FRONTENDS=(
	"2.107 2.107"
	"2.108 2.108"
	"2.109 2.109"
	"2.110 2.110"
	"2.111 2.111"
)

# @ECLASS_VARIABLE: _DLANG_GDC_FRONTENDS
# @INTERNAL
# @DESCRIPTION:
# A list of gdc implementations with their dlang frontend version
#
# The elements are ordered, the higher implementation version has the
# higher index.
#
# Example value for an element:
# @CODE
# "13 2.103"
# @CODE
# Where 13 represents the implementation version and 2.103 represents
# the D language version the implementation supports.
readonly _DLANG_GDC_FRONTENDS=(
	"12 2.100"
	"13 2.103"
	"14 2.108"
	"15 2.111"
)

# @ECLASS_VARIABLE: _DLANG_LDC2_FRONTENDS
# @INTERNAL
# @DESCRIPTION:
# A list of ldc2 implementations with their dlang frontend version.
#
# The elements are ordered, the higher implementation version has the
# higher index.
#
# Example value for an element:
# @CODE
# "1.34 2.104"
# @CODE
# Where 1.34 represents the implementation version and 2.104 represents
# the D language version the implementation supports.
readonly _DLANG_LDC2_FRONTENDS=(
	"1.36 2.106 ~amd64 ~arm64 ~x86"
	"1.37 2.107 ~amd64 ~arm64 ~x86"
	"1.38 2.108 ~amd64 ~arm64 ~x86"
	"1.39 2.109 ~amd64 ~arm64 ~x86"
	"1.40 2.110 ~amd64 ~arm64 ~x86"
)

# @FUNCTION: _dlang_accumulate_implementations
# @INTERNAL
# @DESCRIPTION:
# Set the global variable _DLANG_ALL_IMPLS based on the three arrays:
# _DLANG_(DMD|LDC2|GDC)_FRONTENDS. This function should be called once,
# in global scope.
_dlang_accumulate_implementations() {
	local line result=()
	for line in "${_DLANG_DMD_FRONTENDS[@]/#/dmd-}" \
				"${_DLANG_GDC_FRONTENDS[@]/#/gdc-}" \
				"${_DLANG_LDC2_FRONTENDS[@]/#/ldc2-}"
	do
		line=( ${line} )
		# We only need the first component (name + version)
		local impl=${line[0]/\./_}
		result+=( "${impl}" )
	done

	if [[ ${_DLANG_ALL_IMPLS+1} ]]; then
		if [[ ${_DLANG_ALL_IMPLS[@]} != ${result[@]} ]]; then
			eerror "_DLANG_ALL_IMPLS has changed between inherits!"
			eerror "Before: ${_DLANG_ALL_IMPLS[*]}"
			eerror "Now   : ${result[*]}"
			die "_DLANG_ALL_IMPLS integrity check failed!"
		fi
	else
		_DLANG_ALL_IMPLS=( "${result[@]}" )
		readonly _DLANG_ALL_IMPLS
	fi
}
_dlang_accumulate_implementations
unset -f _dlang_accumulate_implementations

# @ECLASS_VARIABLE: _DLANG_ALL_IMPLS
# @INTERNAL
# @DESCRIPTION:
# All supported Dlang implementations, most preferred last.

# @ECLASS_VARIABLE: _DLANG_HISTORICAL_IMPLS
# @INTERNAL
# @DESCRIPTION:
# All historical Dlang implementations that are no longer supported.
readonly _DLANG_HISTORICAL_IMPLS=(
	dmd-2_106
	dmd-2_105
	dmd-2_104
	dmd-2_103
	dmd-2_102
	dmd-2_101
	ldc2-1_35
	ldc2-1_34
	ldc2-1_33
	ldc2-1_32
	gdc-11
)

# @FUNCTION: _dlang_get_fe_version
# @USAGE: <impl>
# @INTERNAL
# @DESCRIPTION:
# Print the frontend version of the implementation denoted by <impl>, as
# it appears in _DLANG_*_FRONTENDS.
_dlang_get_fe_version() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl="${1/_/.}"

	# Yay, optimizations
	local name=${impl%-*} ver=${impl#*-}
	local arr=_DLANG_${name^^}_FRONTENDS[@]

	local details
	for details in "${!arr}"; do
		if [[ ${details%% *} == ${ver} ]]; then
			local fields=( ${details} )
			echo "${fields[1]}"
			return
		fi
	done

	die "Unknown implementation: ${impl}"
}

fi
