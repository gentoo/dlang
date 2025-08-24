# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dlang-r1.eclass
# @MAINTAINER:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# @AUTHOR:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# Based on python-r1.eclass by Michał Górny <mgorny@gentoo.org> et al
# with logic taken from dlang.eclass by Marco Leise <marco.leise@gmx.de>.
# @BUGREPORTS:
# Please report bugs via https://github.com/gentoo/dlang/issues
# @VCSURL: https://github.com/gentoo/dlang
# @SUPPORTED_EAPIS: 8
# @PROVIDES: dlang-utils
# @BLURB: A common eclass for Dlang packages.
# @DESCRIPTION:
# A common eclass providing helper functions to build and install
# packages supporting being installed for multiple Dlang implementations.
#
# This eclass sets correct IUSE. Modification of REQUIRED_USE has to
# be done by the author of the ebuild (but DLANG_REQUIRED_USE is
# provided for convenience, see below). dlang-r1 exports DLANG_DEPS
# and DLANG_USEDEP so you can create correct dependencies for your
# package easily. It also provides methods to easily run a command for
# each enabled Dlang implementation and duplicate the sources for them.
#
# Please note that dlang-r1 will always inherit dlang-utils as
# well. Thus, all the functions defined there can be used
# in the packages using dlang-r1, and there is no need ever to inherit
# both.
#
# There is one more particularity about the eclass. In order to provide
# correct DLANG_DEPS and DLANG_REQUIRED_USE the contents of KEYWORDS
# need to be set before the inherit, see the example below.
#
# @EXAMPLE:
# @CODE
# EAPI=8
# DLANG_COMPAT=( dmd-2_{101..106} gdc-12 gdc-13 ldc2-1_{32..36} )
# KEYWORDS="amd64 x86"
#
# inherit dlang-r1
#
# REQUIRED_USE=${DLANG_REQUIRED_USE}
# DEPEND="${DLANG_DEPS} dev-libs/gtkd[${DLANG_USEDEP}]"
# RDEPEND=${DEPEND}
# BDEPEND=${DLANG_DEPS}
#
# dlang_src_compile() {
#     emake DC_FLAGS="${DCFLAGS}" LD_FLAGS="${DLANG_LDFLAGS}"
# }
#
# src_compile() {
#     dlang_foreach_impl dlang_src_compile
# }
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_DLANG_R1_ECLASS} ]]; then
_DLANG_R1_ECLASS=1

if [[ ${_DLANG_SINGLE_ECLASS} ]]; then
	die 'dlang-r1.eclass cannot be used with dlang-single.eclass.'
fi

inherit multibuild dlang-utils

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
# in-ebuild DLANG_COMPAT. It is a string listing all the implementations
# which package will be built for. It needs to be specified in the
# calling environment, and not in ebuilds.
#
# It should be noted that in order to preserve metadata immutability,
# DLANG_COMPAT_OVERRIDE does not affect IUSE nor dependencies.
# The state of DLANG_TARGETS is ignored, and all the implementations
# in DLANG_COMPAT_OVERRIDE are built. Dependencies need to be satisfied
# manually.
#
# Example:
# @CODE
# DLANG_COMPAT_OVERRIDE='gdc-13 dmd-2_106' emerge -1v dev-libs/foo
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

# @ECLASS_VARIABLE: BUILD_DIR
# @OUTPUT_VARIABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
# The current build directory. In global scope, it is supposed to
# contain an initial build directory; if unset, it defaults to ${S}.
#
# In functions run by dlang_foreach_impl(), the BUILD_DIR is locally
# set to an implementation-specific build directory. That path is
# created through appending a hyphen and the implementation name
# to the final component of the initial BUILD_DIR.
#
# Example value:
# @CODE
# ${WORKDIR}/foo-1.3-ldc2-1_35
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
# dlang_targets_gdc-12? ( sys-devel/gcc:12[d] dev-util/gdmd:12 )
# dlang_targets_ldc2-1_36? ( dev-lang/ldc2:1.36= )
# dlang_targets_dmd-2_099? ( dev-lang/dmd:2.099= )
# @CODE

# @ECLASS_VARIABLE: DLANG_USEDEP
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated USE-dependency string which can be used to
# depend on another Dlang package being built for the same Dlang
# implementations.
#
# Example use:
# @CODE
# RDEPEND="dev-libs/foo[${DLANG_USEDEP}]"
# @CODE
#
# Example value:
# @CODE
# dlang_targets_gdc-11(-)?,dlang_targets_dmd-2_106(-)?,dlang_targets_ldc2-1_34(-)?
# @CODE

# @ECLASS_VARIABLE: DLANG_REQUIRED_USE
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated required-use expression which ensures that
# at least one Dlang implementation has been enabled.
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
# || ( dlang_targets_gdc-11 dlang_targets_dmd-2_106 dlang_targets_ldc2-1_34 )
# @CODE

# @FUNCTION: _dlang_set_globals
# @INTERNAL
# @DESCRIPTION:
# Sets all the global output variables provided by this eclass.
# This function must be called once, in global scope.
_dlang_set_globals() {
	local deps i DLANG_PKG_DEP

	_dlang_set_impls

	for i in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		_dlang_export "${i}" DLANG_PKG_DEP
		deps+="
		dlang_targets_${i}? (
			${DLANG_PKG_DEP}
		) "
	done

	local flags=( "${_DLANG_SUPPORTED_IMPLS[@]/#/dlang_targets_}" )
	local optflags=${flags[@]/%/(-)?}
	local requse="( || ( ${flags[*]} ) )"
	local usedep=${optflags// /,}

	if [[ ${DLANG_DEPS+1} ]]; then
		# IUSE is magical, so we can't really check it
		# (but we verify DLANG_COMPAT already)

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
		if [[ ${DLANG_USEDEP} != ${usedep} ]]; then
			eerror "DLANG_USEDEP have changed between inherits!"
			eerror "Before: ${DLANG_USEDEP}"
			eerror "Now   : ${usedep}"
			die "DLANG_USEDEP integrity check failed"
		fi
	else
		IUSE=${flags[*]}

		DLANG_DEPS=${deps}
		DLANG_REQUIRED_USE=${requse}
		DLANG_USEDEP=${usedep}
		readonly DLANG_DEPS DLANG_REQUIRED_USE DLANG_USEDEP
	fi
}
_dlang_set_globals
unset -f _dlang_set_globals

# @FUNCTION: _dlang_validate_useflags
# @INTERNAL
# @DESCRIPTION:
# Enforce the proper setting of DLANG_TARGETS, if DLANG_COMPAT_OVERRIDE
# is not in effect. If it is, just warn that the flags will be ignored.
_dlang_validate_useflags() {
	debug-print-function ${FUNCNAME} "${@}"

	if [[ ${DLANG_COMPAT_OVERRIDE} ]]; then
		if [[ ! ${_DLANG_COMPAT_OVERRIDE_WARNED} ]]; then
			ewarn "WARNING: DLANG_COMPAT_OVERRIDE in effect. The following Dlang"
			ewarn "implementations will be enabled:"
			ewarn
			ewarn "	${DLANG_COMPAT_OVERRIDE}"
			ewarn
			ewarn "Dependencies won't be satisfied, and DLANG_TARGETS will be ignored."
			_DLANG_COMPAT_OVERRIDE_WARNED=1
		fi
		# we do not use flags with DCO
		return
	fi

	local i
	for i in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		use "dlang_targets_${i}" && return 0
	done

	eerror "No Dlang implementation selected for the build. Please add one"
	eerror "of the following values to your DLANG_TARGETS (in make.conf):"
	eerror
	eerror "${DLANG_COMPAT[@]}"
	echo
	die "No supported Dlang implementation in DLANG_TARGETS."
}

# @FUNCTION: dlang_copy_sources
# @DESCRIPTION:
# Create a single copy of the package sources for each enabled Dlang
# implementation.
#
# The sources are always copied from initial BUILD_DIR (or S if unset)
# to implementation-specific build directory matching BUILD_DIR used by
# dlang_foreach_impl().
dlang_copy_sources() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS
	_dlang_obtain_impls

	multibuild_copy_sources
}

# @FUNCTION: _dlang_obtain_impls
# @INTERNAL
# @DESCRIPTION:
# Set up the enabled implementation list.
_dlang_obtain_impls() {
	_dlang_validate_useflags

	if [[ ${DLANG_COMPAT_OVERRIDE} ]]; then
		MULTIBUILD_VARIANTS=( ${DLANG_COMPAT_OVERRIDE} )
		return
	fi

	MULTIBUILD_VARIANTS=()

	local impl
	for impl in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		use "dlang_targets_${impl}" && MULTIBUILD_VARIANTS+=( "${impl}" )
	done
}

# @FUNCTION: _dlang_multibuild_wrapper
# @USAGE: <command> [<args>...]
# @INTERNAL
# @DESCRIPTION:
# Initialize the environment for the Dlang implementation selected for
# multibuild.
_dlang_multibuild_wrapper() {
	debug-print-function ${FUNCNAME} "${@}"

	local -x EDC DC DCFLAGS DLANG_LDFLAGS
	local -x PATH=${PATH} PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
	_dlang_export "${MULTIBUILD_VARIANT}" EDC DC DCFLAGS DLANG_LDFLAGS
	_dlang_wrapper_setup "${T}/${MULTIBUILD_ID}"

	pushd "${BUILD_DIR}" > /dev/null || die
	"${@}"
	popd > /dev/null || die
}

# @FUNCTION: dlang_foreach_impl
# @USAGE: <command> [<args>...]
# @DESCRIPTION:
# Run the given command for each of the enabled Dlang implementations.
# If additional parameters are passed, they will be passed through to
# the command.
#
# The function will return 0 status if all invocations succeed.
# Otherwise, the return code from first failing invocation will be
# returned.
#
# For each command being run, BUILD_DIR, EDC, DC, DCFLAGS and
# DLANG_LDFLAGS are set locally, and the latter four are exported to the
# command environment.
dlang_foreach_impl() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS
	_dlang_obtain_impls

	multibuild_foreach_variant _dlang_multibuild_wrapper "${@}"
}

fi
