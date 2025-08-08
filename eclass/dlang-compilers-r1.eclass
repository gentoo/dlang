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
# Contains the available D compiler versions with their stable
# architectures and the language version they support.

if [[ ! ${_DLANG_COMPILERS_R1_ECLASS} ]] ; then
_DLANG_COMPILERS_R1_ECLASS=1

# @ECLASS_VARIABLE: _DLANG_DMD_FRONTENDS
# @INTERNAL
# @DESCRIPTION:
# A list of dmd implementations with their dlang frontend version (which
# happens to coincide with the implementation version) and the
# architectures they support as a list of keywords. Only stable and
# unstable keywords will appear.
#
# The elements are ordered, the higher implementation version has the
# higher index.
#
# Example value for an element:
# @CODE
# "2.102 2.102 ~amd64 x86"
# @CODE
# Where the first 2.102 represents the implementation version,
# the second one represents the D language version the implementation
# supports and, lastly, there are two keywords.
readonly _DLANG_DMD_FRONTENDS=(
	"2.101 2.101 ~amd64 ~x86"
	"2.102 2.102 ~amd64 ~x86"
	"2.103 2.103 ~amd64 ~x86"
	"2.104 2.104 ~amd64 ~x86"
	"2.105 2.105 ~amd64 ~x86"
	"2.106 2.106 ~amd64 ~x86"
	"2.107 2.107 ~amd64 ~x86"
	"2.108 2.108 ~amd64 ~x86"
	"2.109 2.109 ~amd64 ~x86"
	"2.110 2.110 ~amd64 ~x86"
	"2.111 2.111 ~amd64 ~x86"
)

# @ECLASS_VARIABLE: _DLANG_GDC_FRONTENDS
# @INTERNAL
# @DESCRIPTION:
# A list of gdc implementations with their dlang frontend version and
# the architectures they support as a list of keywords. Only stable and
# unstable keywords will appear.
#
# The elements are ordered, the higher implementation version has the
# higher index.
#
# Example value for an element:
# @CODE
# "13 2.103 amd64 ~arm64 x86"
# @CODE
# Where 13 represents the implementation version, 2.103 represents the D
# language version the implementation supports and, lastly, there are
# three keywords.
readonly _DLANG_GDC_FRONTENDS=(
	"12 2.100 ~amd64 ~arm64 ~x86"
	"13 2.103 ~amd64 ~arm64 ~x86"
	"14 2.108 ~amd64 ~arm64 ~x86"
	"15 2.111 ~amd64 ~arm64 ~x86"
)

# @ECLASS_VARIABLE: _DLANG_LDC2_FRONTENDS
# @INTERNAL
# @DESCRIPTION:
# A list of ldc2 implementations with their dlang frontend version and
# the architectures they support as a list of keywords. Only stable and
# unstable keywords will appear.
#
# The elements are ordered, the higher implementation version has the
# higher index.
#
# Example value for an element:
# @CODE
# 1.34 2.104 ~amd64 ~arm64
# @CODE
# Where 1.34 represents the implementation version, 2.104 represents the
# D language version the implementation supports and, lastly, there are
# two keywords.
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
	ldc2-1_35
	ldc2-1_34
	ldc2-1_33
	ldc2-1_32
	gdc-11
)

# @FUNCTION: dlang_compilers_stabs_required_use
# @USAGE: <use_expand_name> [<impls>...]
# @DESCRIPTION:
# Generate a required-use expression which ensures that only supported
# implementations can be selected.
#
# Check _dlang_get_bad_arches for a more detailed description of what
# an implementation being supported means.
#
# <use_expand_name> is a string used to transform implementations as
# they appear in <impls> into USE flags. Possible values are
# "dlang_targets" and "dlang_single_target".
#
# Example: If we had the implementation dmd-2_105 with the keywords,
# i.e. the keywords in _DLANG_DMD_FRONTENDS, `amd64 ~x86' and $KEYWORDS
# has the contents `amd64 arm64 x86' the output should be:
# @CODE
# "<use_expand_name>_dmd-2_105? ( !x86 ) <use_expand_name>_dmd-2_105? ( !arm64 )"
# @CODE
dlang_compilers_stabs_required_use() {
	debug-print-function ${FUNCNAME} "${@}"

	local use_expand_name=${1}
	local impls=( ${@:2} )

	local result=() impl
	for impl in "${impls[@]}"; do
		local badArches=( $(_dlang_get_bad_arches "${impl}") )
		local arch
		for arch in "${badArches[@]}"; do
			result+=( "${use_expand_name}_${impl}? ( !${arch} )" )
		done
	done

	echo "${result[@]}"
}

# @FUNCTION: dlang_compilers_stabs_impl_dep
# @USAGE: <impl> <dep_string>
# @DESCRIPTION:
# Print a dependency string based on <dep_string>, USE disabled on
# architectures found in $KEYWORDS that are not supported by <impl>.
#
# To see what it means for an architecture to be unsupported check
# _dlang_get_bad_arches.
#
# Example: If we had the implementation dmd-2_105 with the keywords,
# i.e. the keywords in _DLANG_DMD_FRONTENDS, `amd64 ~x86' and $KEYWORDS
# has the contents `amd64 arm64 x86' the output should be:
# @CODE
# "!arm64? ( !x86? ( <dep_string> ) ) "
# @CODE
# Where <dep_string> looks like `dlang_single_target_dmd-2_105? ( dev-lang/dmd:2.105= ) '
dlang_compilers_stabs_impl_dep() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl=${1} dep=${2}
	local badArches=( $(_dlang_get_bad_arches "${impl}") )

	local arch
	for arch in "${badArches[@]}"; do
		dep="!${arch}? ( ${dep}) "
	done

	echo "${dep}"
}

# @FUNCTION: _dlang_get_bad_arches
# @USAGE: <impl>
# @INTERNAL
# @DESCRIPTION:
# Output a string of all the arches that are unsupported by <impl> in
# regards to $KEYWORDS.
#
# An architecture is considered unsupported if it:
#
# - appears in $KEYWORDS (either as stable or unstable) and it doesn't
#   appear in the keywords of <impl>, the ones from the
#   _DLANG_*_FRONTENDS arrays.
#
# - appears in $KEYWORDS as stable and it appears in the keywords of
#   <impl> as unstable.
#
# For example, if we had the implementation dmd-2_105 with the keywords,
# i.e. the keywords in _DLANG_DMD_FRONTENDS, `amd64 ~x86' and $KEYWORDS
# has the contents `amd64 arm64 x86' the output should be, in no
# particular order:
# @CODE
# x86 arm64
# @CODE
_dlang_get_bad_arches() {
	debug-print-function ${FUNCNAME} "${@}"

	local details=( $(_dlang_get_impl_details "${1}") )
	local implKeywords=( ${details[@]:2} )

	local result=() keyword
	# Meh, $KEYWORDS can contain -* (like for dmd) and that is globing
	# so bad.
	local keywords
	read -ra keywords <<<"${KEYWORDS}"
	for keyword in "${keywords[@]}"; do
		[[ ${keyword::1} == - ]] && continue

		local arch=${keyword}
		[[ ${keyword::1} == "~" ]] && arch=${keyword:1}

		local found=0
		if [[ ${keyword::1} == "~" ]]; then
			# An unstable package accepts a stable or an unstable implementation
			has "${arch}" "${implKeywords[@]}" && found=1
			has "~${arch}" "${implKeywords[@]}" && found=1
		else
			# A stable package accepts only a stable implementation
			has "${arch}" "${implKeywords[@]}" && found=1
		fi

		if [[ ${found} == 0 ]]; then
			result+=( "${arch}" )
		fi
	done

	echo "${result[@]}"
}

# @FUNCTION: _dlang_get_impl_details
# @USAGE: <impl>
# @INTERNAL
# @DESCRIPTION:
# Print the details of the implementation denoted by <impl>, as they
# appear in _DLANG_*_FRONTENDS.
_dlang_get_impl_details() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl="${1/_/.}"

	# Yay, optimizations
	local name=${impl%-*} ver=${impl#*-}
	local arr=_DLANG_${name^^}_FRONTENDS[@]

	local details
	for details in "${!arr}"; do
		if [[ ${details%% *} == ${ver} ]]; then
			echo "${details}"
			return
		fi
	done

	die "Unknown implementation: ${impl}"
}

fi
