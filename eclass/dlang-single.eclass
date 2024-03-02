# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dlang-single.eclass
# @MAINTAINER:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# @AUTHOR:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# Based on python-utils-r1.eclass by Michał Górny <mgorny@gentoo.org> et al
# with logic taken from dlang.eclass by Marco Leise <marco.leise@gmx.de>.
# @BUGREPORTS:
# Please report bugs via https://github.com/gentoo/dlang/issues
# @VCSURL: https://github.com/gentoo/dlang
# @SUPPORTED_EAPIS: 8
# @PROVIDES: dlang-utils
# @BLURB: An eclass for Dlang packages not installed for multiple implementations.
# @DESCRIPTION:
# An extension of the dlang-r1 eclass suite for packages which don't
# support being installed for multiple Dlang implementations.
#
# This eclass sets correct IUSE. It also provides DLANG_DEPS and
# DLANG_REQUIRED_USE that need to be added to appropriate ebuild
# metadata variables.
#
# The eclass exports DLANG_SINGLE_USEDEP that is suitable for depending
# on other packages using the eclass.  Dependencies on packages using
# dlang-r1 should be created via dlang_gen_cond_dep() function, using
# DLANG_USEDEP placeholder.
#
# Please note that packages which support multiple Dlang implementations
# (using dlang-r1 eclass) can not depend on packages not supporting them
# (using this eclass).
#
# Please note that dlang-single will always inherit dlang-utils as
# well. Thus, all the functions defined there can be used in the
# packages using dlang-single, and there is no need ever to inherit
# both.
#
# Same as dlang-r1.eclass, the contents of $KEYWORDS need to be set
# before the inherit.
#
# @EXAMPLE:
# @CODE
# EAPI=8
# DLANG_COMPAT=( dmd-2_{101..106} gdc-12 gdc-13 ldc2-1_{32..36} )
# KEYWORDS="amd64 x86"
#
# inherit dlang-single
#
# REQUIRED_USE=${DLANG_REQUIRED_USE}
# DEPEND="${DLANG_DEPS} $(dlang_gen_cond_dep '
#     dev-libs/gtkd[${DLANG_USEDEP}]
# ')"
# RDEPEND=${DEPEND}
# BDEPEND=${DLANG_DEPS}
#
# src_compile() {
#     emake DMD="$(dlang_get_dmdw)" DFLAGS="$(dlang_get_dmdw_dcflags)"
# }
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0}  not supported" ;;
esac

if [[ -z ${_DLANG_SINGLE_ECLASS} ]]; then
_DLANG_SINGLE_ECLASS=1

if [[ ${_DLANG_R1_ECLASS} ]]; then
	die 'dlang-single.eclass cannot be used with dlang-r1.eclass.'
fi

inherit dlang-utils

# @ECLASS_VARIABLE: DLANG_COMPAT
# @REQUIRED
# @PRE_INHERIT
# @DESCRIPTION:
# This variable contains a list of Dlang implementations the package
# supports. It must be set before the `inherit' call. It has to be an
# array.
#
# Example:
# @CODE
# DLANG_COMPAT=( gdc-12 ldc2-1_36 dmd-2_102 dmd-2_103 )
# @CODE
#
# Please note that you can also use bash brace expansion if you like:
# @CODE
# DLANG_COMPAT=( gdc-1{2..3} ldc2-1_{29..36} dmd-2_10{5,6} )
# @CODE

# @ECLASS_VARIABLE: DLANG_COMPAT_OVERRIDE
# @USER_VARIABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
# This variable can be used when working with ebuilds to override the
# in-ebuild DLANG_COMPAT. It is a string naming the implementation which
# package will be built for. It needs to be specified in the calling
# environment, and not in ebuilds.
#
# It should be noted that in order to preserve metadata immutability,
# DLANG_COMPAT_OVERRIDE does not affect IUSE nor dependencies. The state
# of DLANG_TARGETS is ignored, and all the implementations in
# DLANG_COMPAT_OVERRIDE are built. Dependencies need to be satisfied
# manually.
#
# Example:
# @CODE
# DLANG_COMPAT_OVERRIDE='gdc-13' emerge -1v dev-libs/foo
# @CODE

# @ECLASS_VARIABLE: DLANG_REQ_USE
# @DEFAULT_UNSET
# @PRE_INHERIT
# @DESCRIPTION:
# An associative array of Dlang implementations and USE-dependencies
# strings. The keys are implementation names, so: "dmd" "ldc2" or "gdc";
# and the values are the aforementioned USE-dependency strings.
#
# This should be set before calling `inherit'.
#
# Example:
# @CODE
# declare -A DLANG_REQ_USE=(
#     [dmd]="static-libs(-)?"
#     [gdc]="another_flag"
#     [ldc2]="static-libs(-)?"
# )
# @CODE
#
# It will cause the Dlang dependencies to look like:
# @CODE
# dlang_targets_ldc2-X_Y? ( dev-lang/ldc2:X.Y=[static-libs(-)?] )
# dlang_targets_gdc-X? ( sys-devel/gcc[d,another_flag]:X dev-util/gdmd:X )
# dlang_targets_dmd-X_Y? ( dev-lang/dmd:X.Y=[static-libs(-)?] )
# @CODE

# @ECLASS_VARIABLE: DLANG_DEPS
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated Dlang dependency string for all
# implementations listed in DLANG_COMPAT.
#
# Example use:
# @CODE
# RDEPEND="${DLANG_DEPS}
#	dev-foo/mydep"
# DEPEND=${RDEPEND}
# @CODE
#
# Example value:
# @CODE
# dlang_single_target_gdc-12? ( sys-devel/gcc:12[d] dev-util/gdmd:12 )
# dlang_single_target_ldc2-1_36? ( dev-lang/ldc2:1.36= )
# dlang_single_target_dmd-2_099? ( dev-lang/dmd:2.099= )
# @CODE

# @ECLASS_VARIABLE: DLANG_SINGLE_USEDEP
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated USE-dependency string which can be used to
# depend on another dlang-single package being built for the same Dlang
# implementation.
#
# If you need to depend on a multi-impl (dlang-r1) package, use
# dlang_gen_cond_dep with DLANG_USEDEP placeholder instead.
#
# Example use:
# @CODE
# RDEPEND="dev-util/foo[${DLANG_SINGLE_USEDEP}]"
# @CODE
#
# Example value:
# @CODE
# dlang_single_target_gdc-13(-)?
# @CODE

# @ECLASS_VARIABLE: DLANG_USEDEP
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is a placeholder variable supported by dlang_gen_cond_dep, in
# order to depend on dlang-r1 packages built for the same Dlang
# implementation.
#
# Example use:
# @CODE
# RDEPEND="$(dlang_gen_cond_dep '
#     dev-libs/foo[${DLANG_USEDEP}]
#   ')"
# @CODE
#
# Example value:
# @CODE
# dlang_targets_ldc2-1_35(-)
# @CODE

# @ECLASS_VARIABLE: DLANG_REQUIRED_USE
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated required-use expression which ensures that
# exactly one DLANG_SINGLE_TARGET value has been enabled.
#
# This expression should be utilized in an ebuild by including it in
# REQUIRED_USE, optionally behind a use flag.
#
# Example use:
# @CODE
# REQUIRED_USE="^^ ( selfhost ${DLANG_REQUIRED_USE} )"
# @CODE
#
# Example value:
# @CODE
# ^^ ( dlang_single_target_gdc-11 dlang_single_target_dmd-2_106 dlang_single_target_ldc2-1_34 )
# @CODE

# @FUNCTION: _dlang_single_set_globals
# @INTERNAL
# @DESCRIPTION:
# Sets all the global output variables provided by this eclass.
# This function must be called once, in global scope.
_dlang_single_set_globals() {
	_dlang_set_impls

	local flags=( "${_DLANG_SUPPORTED_IMPLS[@]/#/dlang_single_target_}" )

	if [[ ${#_DLANG_SUPPORTED_IMPLS[@]} -eq 1 ]]; then
		# if only one implementation is supported, use IUSE defaults to
		# avoid requesting the user to enable it
		IUSE="+${flags[0]}"
	else
		IUSE="${flags[*]}"
	fi

	local stabilization_mock=$(dlang_compilers_stabs_required_use \
								   dlang_single_target \
								   "${_DLANG_SUPPORTED_IMPLS[@]}"
		  )
	local requse="( ^^ ( ${flags[*]} )${stabilization_mock:+ ${stabilization_mock}} )"
	local single_flags="${flags[@]/%/(-)?}"
	local single_usedep=${single_flags// /,}

	local deps= i DLANG_PKG_DEP
	for i in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		_dlang_export "${i}" DLANG_PKG_DEP
		deps+=$(
			dlang_compilers_stabs_impl_dep \
				"${i}" \
				"dlang_single_target_${i}? (
					${DLANG_PKG_DEP}
				) "
			 )
	done

	if [[ ${DLANG_DEPS+1} ]]; then
		if [[ ${DLANG_DEPS} != ${deps} ]]; then
			eerror "DLANG_DEPS have changed between inherits (DLANG_REQ_USE?)!"
			eerror "Before: ${DLANG_DEPS}"
			eerror "Now   : ${deps}"
			die "DLANG_DEPS integrity check failed"
		fi

		if [[ ${DLANG_REQUIRED_USE} != ${requse} ]]; then
			eerror "DLANG_REQUIRED_USE have changed between inherits!"
			eerror "Before: ${DLANG_REQUIRED_USE}"
			eerror "Now   : ${requse}"
			die "DLANG_REQUIRED_USE integrity check failed"
		fi

		# this one's a formality -- it depends on DLANG_COMPAT only
		if [[ ${DLANG_SINGLE_USEDEP} != ${single_usedep} ]]; then
			eerror "DLANG_SINGLE_USEDEP have changed between inherits!"
			eerror "Before: ${DLANG_SINGLE_USEDEP}"
			eerror "Now   : ${single_usedep}"
			die "DLANG_SINGLE_USEDEP integrity check failed"
		fi
	else
		DLANG_DEPS=${deps}
		DLANG_REQUIRED_USE=${requse}
		DLANG_USEDEP='%DLANG_USEDEP-NEEDS-TO-BE-USED-IN-DLANG_GEN_COND_DEP%'
		DLANG_SINGLE_USEDEP=${single_usedep}
		readonly DLANG_DEPS DLANG_REQUIRED_USE DLANG_SINGLE_USEDEP \
			DLANG_USEDEP
	fi
}
_dlang_single_set_globals
unset -f _dlang_single_set_globals

# @FUNCTION: dlang_gen_cond_dep
# @USAGE: <dependency> [<pattern>...]
# @DESCRIPTION:
# Output a list of <dependency>-ies made conditional to USE flags of
# Dlang implementations which are both in DLANG_COMPAT and match any of
# the patterns passed as the remaining parameters.
#
# For the pattern syntax, please see _dlang_impl_matches
# in dlang-utils.eclass.
#
# In order to enforce USE constraints on the packages, verbatim
# '${DLANG_SINGLE_USEDEP}' and '${DLANG_USEDEP}' (quoted!) may
# be placed in the dependency specification. It will get expanded within
# the function into a proper USE dependency string.
#
# Example:
# @CODE
# DLANG_COMPAT=( gdc-1{2,3} ldc2-1_36 dmd-2_{101..106} )
# RDEPEND="$(dlang_gen_cond_dep \
#   'dev-libs/gtkd[${DLANG_USEDEP}]' 'gdc*')"
# @CODE
#
# It will cause the variable to look like:
# @CODE
# RDEPEND="dlang_single_target_gdc-12? (
#     dev-libs/gtkd[dlang_targets_gdc-12(-),...] )
#  dlang_single_target_gdc-13? (
#     dev-libs/gtkd[dlang_targets_gdc-13(-),...] )
# @CODE
dlang_gen_cond_dep() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl matches=()

	local dep=${1}
	shift

	_dlang_verify_patterns "${@}"
	for impl in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		if _dlang_impl_matches "${impl}" "${@}"; then
			local single_usedep="dlang_single_target_${impl}(-)"
			local multi_usedep="dlang_targets_${impl}(-)"

			local subdep=${dep//\$\{DLANG_SINGLE_USEDEP\}/${single_usedep}}
			matches+=( "dlang_single_target_${impl}? (
				${subdep//\$\{DLANG_USEDEP\}/${multi_usedep}} )" )
		fi
	done

	echo "${matches[@]}"
}

# @FUNCTION: dlang_setup
# @DESCRIPTION:
# Determine what the selected Dlang implementation is and set the Dlang
# build environment up for it.
dlang_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	unset EDC

	# support developer override
	if [[ ${DLANG_COMPAT_OVERRIDE} ]]; then
		local impls=( ${DLANG_COMPAT_OVERRIDE} )
		[[ ${#impls[@]} -eq 1 ]] || die "DLANG_COMPAT_OVERRIDE must name exactly one implementation for dlang-single"

		ewarn "WARNING: DLANG_COMPAT_OVERRIDE in effect. The following Dlang"
		ewarn "implementation will be used:"
		ewarn
		ewarn "	${DLANG_COMPAT_OVERRIDE}"
		ewarn
		ewarn "Dependencies won't be satisfied, and DLANG_SINGLE_TARGET flags will be ignored."

		_dlang_export "${impls[0]}" EDC DC DCFLAGS DLANG_LDFLAGS
		_dlang_wrapper_setup
		einfo "Using ${EDC} to build"
		return
	fi

	local impl
	for impl in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		if use "dlang_single_target_${impl}"; then
			if [[ ${EDC} ]]; then
				eerror "Your DLANG_SINGLE_TARGET setting lists more than a single Dlang"
				eerror "implementation. Please set it to just one value. If you need"
				eerror "to override the value for a single package, please use package.use"
				eerror "or an equivalent solution (man 5 portage)."
				echo
				die "More than one implementation in DLANG_SINGLE_TARGET."
			fi

			_dlang_export "${impl}" EDC DC DCFLAGS DLANG_LDFLAGS
			_dlang_wrapper_setup
			einfo "Using ${EDC} to build"
		fi
	done

	if [[ ! ${EDC} ]]; then
		eerror "No Dlang implementation selected for the build. Please set"
		eerror "the DLANG_SINGLE_TARGET variable in your make.conf to one"
		eerror "of the following values:"
		eerror
		eerror "${_DLANG_SUPPORTED_IMPLS[@]}"
		echo
		die "No supported Dlang implementation in DLANG_SINGLE_TARGET."
	fi
}

# @FUNCTION: dlang-single_pkg_setup
# @DESCRIPTION:
# Runs dlang_setup.
dlang-single_pkg_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${MERGE_TYPE} != binary ]] && dlang_setup
}

fi

EXPORT_FUNCTIONS pkg_setup
