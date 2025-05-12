# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dlang-utils.eclass
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
# @PROVIDES: dlang-compilers-r1
# @BLURB: Utility functions for packages with Dlang parts.
# @DESCRIPTION:
# A utility eclass providing functions to query Dlang implementations
# and install Dlang libraries.
#
# This eclass does not set any metadata variables nor export any phase
# functions. It can be inherited safely.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ ! ${_DLANG_UTILS_R1_ECLASS} ]]; then
_DLANG_UTILS_R1_ECLASS=1

inherit dlang-compilers-r1 multilib toolchain-funcs

# @ECLASS_VARIABLE: DMDFLAGS
# @USER_VARIABLE
# @DESCRIPTION:
# Flags that will be passed to dmd implementations during compilation.
#
# Example value:
# @CODE
# -O -release -mcpu=native
# @CODE

# @ECLASS_VARIABLE: GDCFLAGS
# @USER_VARIABLE
# @DESCRIPTION:
# Flags that will be passed to gdc implementations during compilation.
#
# Example value:
# @CODE
# -O2 -pipe -march=native -frelease
# @CODE

# @ECLASS_VARIABLE: LDCFLAGS
# @USER_VARIABLE
# @DESCRIPTION:
# Flags that will be passed to ldc2 implementations during compilation.
#
# Example value:
# @CODE
# -O2 -release -mcpu=native
# @CODE

# @FUNCTION: _dlang_set_impls
# @INTERNAL
# @DESCRIPTION:
# Set two global variables based on DLANG_COMPAT
#
# - _DLANG_SUPPORTED_IMPLS containing valid implementations supported
#   by the ebuild (DLANG_COMPAT - dead implementations),
#
# - and _DLANG_UNSUPPORTED_IMPLS containing valid implementations that
#   are not supported by the ebuild.
#
# Implementations in both variables are ordered using the pre-defined
# eclass implementation ordering.
#
# This function must be called once in global scope by an eclass
# utilizing DLANG_COMPAT.
_dlang_set_impls() {
	if ! declare -p DLANG_COMPAT &>/dev/null; then
		die 'DLANG_COMPAT not declared.'
	fi
	if [[ ${DLANG_COMPAT@a} != *a* ]]; then
		die 'DLANG_COMPAT must be an array'
	fi

	local supp=() unsupp=()

	local i
	for i in "${_DLANG_ALL_IMPLS[@]}"; do
		if has "${i}" "${DLANG_COMPAT[@]}"; then
			supp+=( "${i}" )
		else
			unsupp+=( "${i}" )
		fi
	done

	if [[ ! ${supp[@]} ]]; then
		die "No supported implementation in DLANG_COMPAT."
	fi

	if [[ ${_DLANG_SUPPORTED_IMPLS[@]} ]]; then
		# set once already, verify integrity
		if [[ ${_DLANG_SUPPORTED_IMPLS[@]} != ${supp[@]} ]]; then
			eerror "Supported impls (DLANG_COMPAT) changed between inherits!"
			eerror "Before: ${_DLANG_SUPPORTED_IMPLS[*]}"
			eerror "Now   : ${supp[*]}"
			die "_DLANG_SUPPORTED_IMPLS integrity check failed"
		fi
		if [[ ${_DLANG_UNSUPPORTED_IMPLS[@]} != ${unsupp[@]} ]]; then
			eerror "Unsupported impls changed between inherits!"
			eerror "Before: ${_DLANG_UNSUPPORTED_IMPLS[*]}"
			eerror "Now   : ${unsupp[*]}"
			die "_DLANG_UNSUPPORTED_IMPLS integrity check failed"
		fi
	else
		_DLANG_SUPPORTED_IMPLS=( "${supp[@]}" )
		_DLANG_UNSUPPORTED_IMPLS=( "${unsupp[@]}" )
		readonly _DLANG_SUPPORTED_IMPLS _DLANG_UNSUPPORTED_IMPLS
	fi
}

# @ECLASS_VARIABLE: DC
# @DEFAULT_UNSET
# @DESCRIPTION:
# The absolute path to the current Dlang compiler.
#
# Example values (each line is a possible value):
# @CODE
# /usr/lib/ldc2/1.36/bin/ldc2
# /usr/lib/dmd/2.106/bin/dmd
# /usr/x86_64-pc-linux-gnu/gcc-bin/12/gdc
# @CODE

# @ECLASS_VARIABLE: EDC
# @DEFAULT_UNSET
# @DESCRIPTION:
# The executable name of the current Dlang compiler.
#
# Please note that this names don't necessarily map to actual
# executables in $PATH so there's no guarantee that calling $EDC will
# work. Instead, use $DC or $(dlang_get_dmdw).
#
# Example values (each line is a possible value):
# @CODE
# dmd-2.106
# ldc2-1.32
# gdc-12
# @CODE

# @ECLASS_VARIABLE: DCFLAGS
# @DEFAULT_UNSET
# @DESCRIPTION:
# The flags the user provided for the current Dlang implementation.
#
# Example value:
# @CODE
# --O2 --release
# @CODE

# @ECLASS_VARIABLE: DLANG_LDFLAGS
# @DEFAULT_UNSET
# @DESCRIPTION:
# The contents of $LDFLAGS converted to something the current Dlang
# implementation can understand.
#
# Example value:
# @CODE
# -L--as-needed -L-O1
# @CODE

# @FUNCTION: dlang_get_dmdw
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the full path of the dmd wrapper for the current
# implementation. If no implementation is provided, ${EDC} will be
# used.
dlang_get_dmdw() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DMDW
	echo "${DMDW}"
}

# @FUNCTION: dlang_get_dmdw_dcflags
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the user flags for the compiler denoted by given
# implementation, in a form that can be passed to the dmd wrapper of the
# same compiler. If no implementation is provided, ${EDC} will be used.
dlang_get_dmdw_dcflags() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DMDW_DCFLAGS
	echo "${DMDW_DCFLAGS}"
}

# @FUNCTION: dlang_get_dmdw_ldflags
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the contents of $LDFLAGS, converted to what the dmd
# wrapper of the given implementation understands. If no implementation
# is provided, ${EDC} will be used.
dlang_get_dmdw_ldflags() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_DMDW_LDFLAGS
	echo "${DLANG_DMDW_LDFLAGS}"
}

# @FUNCTION: dlang_get_libdir
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the path to the library directory of the current
# implementation. If no implementation is provided, ${EDC} will be used.
#
# This function uses $ABI to calculate to result. For packages that
# support multiple abis care must be taken to set $ABI properly _before_
# calling this function.
dlang_get_libdir() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_LIBDIR
	echo "${DLANG_LIBDIR}"
}

# @FUNCTION: dlang_get_import_dir
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the path to the include directory shared across
# implementations. This value doesn't depend on <impl> as it is always:
# @CODE
# /usr/include/dlang
# @CODE
dlang_get_import_dir() {
	debug-print-function ${FUNCNAME} "${@}"

	echo "/usr/include/dlang"
}

# @FUNCTION: dlang_get_fe_version
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the frontend version of the given Dlang
# implementation. If no implementation is provided, ${EDC} will be used.
#
# Example:
# @CODE
# dlang_get_fe_version dmd-2.101 # echo 2.101
# dlang_get_fe_version ldc-1_35  # echo 2.105
# dlang_get_fe_version gdc-12    # echo 2.100
# @CODE
dlang_get_fe_version() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_FE_VERSION
	echo "${DLANG_FE_VERSION}"
}

# @FUNCTION: dlang_get_be_version
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the backend version of the given Dlang
# implementation. If no implementation is provided, ${EDC} will be used.
#
# Example:
# @CODE
# dlang_get_be_version dmd-2.101 # echo 2.101
# dlang_get_be_version ldc-1_35  # echo 1.35
# dlang_get_be_version gdc-12    # echo 12
# @CODE
dlang_get_be_version() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_BE_VERSION
	echo "${DLANG_BE_VERSION}"
}

# @FUNCTION: dlang_get_debug_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler debug flag for the given
# implementation. If no implementation is provided, ${EDC} will be
# used.
dlang_get_debug_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_DEBUG_FLAG
	echo "${DLANG_DEBUG_FLAG}"
}

# @FUNCTION: dlang_get_linker_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler linker flag for the given
# implementation. If no implementation is provided, ${EDC} will be
# used.
dlang_get_linker_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_LINKER_FLAG
	echo "${DLANG_LINKER_FLAG}"
}

# @FUNCTION: dlang_get_main_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler -main flag (include an empty main) for
# the given implementation. If no implementation is provided, ${EDC}
# will be used.
dlang_get_main_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_MAIN_FLAG
	echo "${DLANG_MAIN_FLAG}"
}

# @FUNCTION: dlang_get_model_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print a flag to be appended to $DCFLAGS to compile for the
# current ABI. If no implementation is provided, ${EDC} will be used.
#
# If not in a multilib profile nothing will be printed. If on amd64/x86
# multilib, which is the only one supported by the eclass, either -m64
# or -m32 is printed based on the value of $ABI.
#
# Since all implementations accept the -m* flag the value of <impl>
# doesn't matter.
dlang_get_model_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_MODEL_FLAG
	echo "${DLANG_MODEL_FLAG}"
}

# @FUNCTION: dlang_get_output_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler output flag for the given
# implementation. If no implementation is provided, ${EDC} will be
# used.
dlang_get_output_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_OUTPUT_FLAG
	echo "${DLANG_OUTPUT_FLAG}"
}

# @FUNCTION: dlang_get_unittest_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler unittest flag for the given
# implementation. If no implementation is provided, ${EDC} will be
# used.
dlang_get_unittest_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_UNITTEST_FLAG
	echo "${DLANG_UNITTEST_FLAG}"
}

# @FUNCTION: dlang_get_version_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler version flag for the given
# implementation. If no implementation is provided, ${EDC} will be
# used.
dlang_get_version_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_VERSION_FLAG
	echo "${DLANG_VERSION_FLAG}"
}

# @FUNCTION: dlang_get_wno_error_flag
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler flag which turns warnings into messaged
# instead of errors for the given implementation. If no implementation
# is provided, ${EDC} will be used.
dlang_get_wno_error_flag() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_WNO_ERROR_FLAG
	echo "${DLANG_WNO_ERROR_FLAG}"
}

# @FUNCTION: dlang_print_system_import_paths
# @USAGE: [<impl>]
# @DESCRIPTION:
# Print a list of standard import paths, $EPREFIX included, for the
# current Dlang implementation. If no implementation is provided, ${EDC}
# will be used.
#
# The entries are each printed on a separate line. Entries include the
# paths to phobos, druntime and implementation specific directories, if
# any.
dlang_print_system_import_paths() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_SYSTEM_IMPORT_PATHS
	echo "${DLANG_SYSTEM_IMPORT_PATHS}"
}

# @VARIABLE: imports
# @DEFAULT_UNSET
# @DESCRIPTION:
# A space separated list of import paths that dlang_compile_* will add
# to the command line during compilation.
#
# Example usage:
# @CODE
# local imports="mydir/mylib subdir"
# dlang_compile_bin main main.d # dmd -ofmain main.d -Imydir/mylib -Isubdir
# @CODE

# @VARIABLE: string_imports
# @DEFAULT_UNSET
# @DESCRIPTION:
# A space separated list of string import paths that dlang_compile_*
# will add to the command line during compilation.
#
# Example usage:
# @CODE
# local string_imports="pix more/pix"
# dlang_compile_bin main main.d # dmd -ofmain main.d -Jpix -Jmore/pix
# @CODE

# @VARIABLE: versions
# @DEFAULT_UNSET
# @DESCRIPTION:
# A space separated list of versions that dlang_compile_* will enable
# during compilation.
#
# Example usage:
# @CODE
# local versions="foo bar"
# dlang_compile_bin main main.d # dmd -ofmain main.d -version=foo -version=bar
# @CODE

# @VARIABLE: libs
# @DEFAULT_UNSET
# @DESCRIPTION:
# A space separated list of libraries that dlang_compile_* will link with.
#
# Example usage:
# @CODE
# local libs="gtkd gtk"
# dlang_compile_bin main main.d # dmd -ofmain main.d -L-lgtkd -L-lgtk
# @CODE

# @FUNCTION: dlang_compile_lib.so
# @USAGE: <output> <soname> <args>...
# @DESCRIPTION:
# Compiles a D shared library. The first argument is the output file
# name, the second argument is the soname (typically file name without
# patch level suffix), the other arguments are source files or arguments
# for the compiler.
#
# Additional variables can be set to fine tune the compilation.
# Check $imports, $string_imports, $versions and $libs.
dlang_compile_lib.so() {
	debug-print-function ${FUNCNAME} "${@}"

	local libname="${1}"
	local soname="${2}"
	local sources="${@:3}"

	# See dlang_compile_bin comment about these variables.
	#local DC DCFLAGS DLANG_LDFLAGS
	local DLANG_MODEL_FLAG DLANG_LINKER_FLAG DLANG_OUTPUT_FLAG
	_dlang_export DLANG_MODEL_FLAG DLANG_LINKER_FLAG DLANG_OUTPUT_FLAG

	# Put these variables here instead of in _dlang_export to not
	# complicate it any further.
	local so_flags=$(_dlang_echo_implementation_string \
						 "${EDC}" \
						 "-shared -defaultlib=libphobos2.so -fPIC" \
						 "-shared -fpic" \
						 "-shared -relocation-model=pic")

	local cmd=(
		${DC} $(_dlang_compile_extra_flags)
		${DLANG_MODEL_FLAG}
		${so_flags}
		${DLANG_LINKER_FLAG}-soname=${soname}
		${DLANG_OUTPUT_FLAG}${libname}
		${sources}
		# Put the user flags last
		${DCFLAGS} ${DLANG_LDFLAGS}
	)

	dlang_exec "${cmd[@]}"
}

# @FUNCTION: dlang_compile_lib.a
# @USAGE: <output> <args>...
# @DESCRIPTION:
# Compiles a D static library. The first argument is the output file
# name, the other arguments are source files or arguments to the
# compiler.
#
# Additional variables can be set to fine tune the compilation.
# Check $imports, $string_imports, $versions and $libs.
dlang_compile_lib.a() {
	debug-print-function ${FUNCNAME} "${@}"

	local libname="${1}"
	local sources="${@:2}"

	# See dlang_compile_bin comment about these variables.
	#local DC DCFLAGS DLANG_LDFLAGS
	local DLANG_MODEL_FLAG DLANG_LINKER_FLAG DLANG_OUTPUT_FLAG
	_dlang_export DLANG_MODEL_FLAG DLANG_LINKER_FLAG DLANG_OUTPUT_FLAG

	if [[ ${EDC::3} == @(dmd|ldc) ]]; then
		# Put these variables here instead of in _dlang_export to not
		# complicate it any further.
		local a_flags=$(_dlang_echo_implementation_string \
							"${EDC}" \
							"-lib -fPIC" \
							"" \
							"-lib -relocation-model=pic")

		local cmd=(
			${DC} $(_dlang_compile_extra_flags)
			${DLANG_MODEL_FLAG}
			${a_flags}
			${DLANG_OUTPUT_FLAG}${libname}
			${sources}
			# Put the user flags last
			${DCFLAGS} ${DLANG_LDFLAGS}
		)

		dlang_exec "${cmd[@]}"
	else
		# 2 step, first compile, then ar
		local tmpFile=${libname}.dlang-eclass.o
		local cmd=(
			${DC} $(_dlang_compile_extra_flags)
			${DLANG_MODEL_FLAG}
			-c ${DLANG_OUTPUT_FLAG}${tmpFile}
			${sources}
			# Put the user flags last
			${DCFLAGS} ${DLANG_LDFLAGS}
		)
		dlang_exec "${cmd[@]}"

		cmd=( $(tc-getAR) ${ARFLAGS} rcs ${libname} ${tmpFile} )
		dlang_exec "${cmd[@]}"
	fi
}

# @FUNCTION: dlang_compile_bin
# @USAGE: <output> <args>...
# @DESCRIPTION:
# Compiles a D application. The first argument is the output file name,
# the other arguments are source files or compiler arguments.
#
# Additional variables can be set to fine tune the compilation.
# Check $imports, $string_imports, $versions and $libs.
dlang_compile_bin() {
	debug-print-function ${FUNCNAME} "${@}"
	local output=${1} sources=${@:2}

	# These should already be set by dlang-r1 or dlang-single
	#local DC DCFLAGS DLANG_LDFLAGS
	# We don't set them here to support dmd[selfhost] which
	# wants to overwrite some of these values.
	local DLANG_OUTPUT_FLAG
	_dlang_export DLANG_OUTPUT_FLAG

	local cmd=(
		${DC} $(_dlang_compile_extra_flags)
		${DLANG_OUTPUT_FLAG}${output}
		${sources}
		# Put the user flags last.
		${DCFLAGS} ${DLANG_LDFLAGS}
	)

	dlang_exec "${cmd[@]}"
}

# @FUNCTION: dlang_exec
# @USAGE: <cmd>...
# @DESCRIPTION:
# Execute the command passed as arguments, die on failure.
dlang_exec() {
	echo "${@}"
	${@} || die
}

# @FUNCTION: dlang_dolib.so
# @USAGE: <passthrough-args>...
# @DESCRIPTION:
# A dolib.so wrapper that will install the library to the library
# directory of the current Dlang implementation, denoted by ${EDC}.
#
# The `into' destination needs to be `/usr', if you changed it do:
# @CODE
# into /usr
# @CODE
# before running this function.
dlang_dolib.so() {
	debug-print-function ${FUNCNAME} "${@}"

	local DLANG_LIBDIR
	_dlang_export DLANG_LIBDIR

	local LIBDIR_${ABI}=${DLANG_LIBDIR}
	dolib.so "${@}"
}

# @FUNCTION: dlang_dolib.a
# @USAGE: <passthrough-args>...
# @DESCRIPTION:
# A dolib.a wrapper that will install the library to the library
# directory of the current Dlang implementation, denoted by ${EDC}.
#
# The `into' destination needs to be `/usr', if you changed it before do:
# @CODE
# into /usr
# @CODE
# before running this function.
dlang_dolib.a() {
	debug-print-function ${FUNCNAME} "${@}"

	local DLANG_LIBDIR
	_dlang_export DLANG_LIBDIR

	local LIBDIR_${ABI}=${DLANG_LIBDIR}
	dolib.a "${@}"
}

# @FUNCTION: dlang_get_dcflags
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the flags the user has set up for the given
# implementation. If no implementation is provided, ${EDC} will be used.
#
# See also: $DMDFLAGS, $GDCFLAGS, $LDCFLAGS
dlang_get_dcflags() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DCFLAGS
	echo "${DCFLAGS}"
}

# @FUNCTION: dlang_get_ldflags
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the contents of $LDFLAGS, converted to what the given
# implementation understands. If no implementation is provided, ${EDC}
# will be used.
dlang_get_ldflags() {
	debug-print-function ${FUNCNAME} "${@}"

	_dlang_export "${@}" DLANG_LDFLAGS
	echo "${DLANG_LDFLAGS}"
}

# @FUNCTION: dlang-filter-dflags
# @USAGE: <pattern> <flags>
# @DESCRIPTION:
# Remove particular <flags> from {DMD,GDC,LDC}FLAGS based on
# <pattern> and also from {DMDW_,}DCFLAGS if they are set.
# <flags> accept shell globs.
#
# For the syntax of <pattern> please see _dlang_impl_matches.
# Note that you will probably want to use globbing for the pattern
# and restrict to one of the three compilers, e.g. "dmd*", "gdc*".
#
# Example:
# @CODE
# DMDFLAGS="-a -b -c -d -e -ff"
# dlang-filter-dflags "dmd*" -e
# echo "${DMDFLAGS}" # "-a -b -c -d -ff"
# @CODE
#
# @CODE
# DCFLAGS="-a -b -c -d -e -ff"
# dlang-filter-dflags '*' '-?'
# echo "${DCFLAGS}" # "-ff"
# @CODE
#
# @CODE
# LDCFLAGS='-O -O1 -flag -O3'
# dlang-filter-dflags 'ldc*' '-O*'
# echo "${LDCFLAGS}" # "-flag"
# @CODE
dlang-filter-dflags() {
	local pattern="${1}"
	shift

	_dlang_verify_patterns "${pattern}"

	# One implementation from each compiler, the
	# version doesn't matter.
	local impl
	for impl in ldc2-1.32 dmd-2.102 gdc-12; do
		if _dlang_impl_matches "${impl}" "${pattern}"; then
			local flagVar="${impl::3}" # either dmd, gdc or ldc
			flagVar="${flagVar^^}FLAGS" # {DMD,GDC,LDC}FLAGS

			# Taken from _filter-var from flag-o-matic.eclass
			local x f new=()
			for f in ${!flagVar}; do
				for x; do
					[[ ${f} == ${x} ]] && continue 2
				done
				new+=( "${f}" )
			done

			export ${flagVar}="${new[*]}"
		fi
	done

	# If the flags are set, udpate them.
	for v in {DMDW_,}DCFLAGS; do
		[[ ${v} ]] && _dlang_export "${v}"
	done

	return 0
}

# @FUNCTION: dlang_get_abi_bits
# @USAGE: [<abi>]
# @DESCRIPTION:
# Echo the bits of the given abi. When unspecified take the value from
# $ABI.
#
# If the abi is x86, echo 32, if amd64 echo 64, otherwise do nothing.
dlang_get_abi_bits() {
	case "${1:-${ABI}}" in
		amd64*) echo 64 ;;
		x86*) echo 32 ;;
	esac
}

# @FUNCTION: _dlang_export
# @USAGE: [<impl>] <variables>...
# @INTERNAL
# @DESCRIPTION:
# Set and export the Dlang implementation-relevant variables passed
# as parameters.
#
# The optional first parameter may specify the requested Dlang
# implementation (either as DLANG_TARGETS value, e.g. dmd-2_106,
# ldc2-1_32, gdc-12, or an EDC one, e.g. dmd-2.106, ldc2-1.32, gdc-12).
# If no implementation has been passed, the current one will be obtained
# from ${EDC}.
#
# Some variables, like DLANG_LIBIDR and DLANG_MODEL_FLAG, are calculated
# based on $ABI. For this reason ebuilds that handle multiple abis
# should handle first the abis then the dlang portions. Shortly:
# @CODE
# multilib_foreach_abi dlang_foreach_impl some_function # good
# dlang_foreach_impl multilib_foreach_abi some_function # bad
# @CODE
#
# Note that there is one more form of <impl> that is accepted. It may be
# in the form "dmd-wrap-<actual_impl>" where <actual_impl> is in the
# form described above. This is only used internally to keep LDFLAGS
# logic in the same place. Be aware of this but don't use it unless
# necessary or it will become hard to keep track of stuff very fast.
_dlang_export() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl
	case "${1}" in
		dmd-*|ldc2-*|gdc-*)
			impl=${1/_/.}
			shift
			;;
		*)
			impl=${EDC}
			if [[ -z ${impl} ]]; then
				die "_dlang_export called without a dlang implementation and EDC is unset"
			fi
			;;
	esac
	debug-print "${FUNCNAME}: implementation: ${impl}"

	local var
	for var; do
		case "${var}" in
			EDC)
				export EDC=${impl}
				debug-print "${FUNCNAME}: EDC = ${EDC}"
				;;
			DC)
				export DC=$(
					_dlang_echo_implementation_string \
						"${impl}" \
						"${EPREFIX}/usr/lib/dmd/${impl#dmd-}/bin/dmd" \
						"${EPREFIX}/usr/${CHOST_default}/gcc-bin/${impl#gdc-}/gdc" \
						"${EPREFIX}/usr/lib/ldc2/${impl#ldc2-}/bin/ldc2"
					   )
				# We could have the path, in the case of gdc, be ${CHOST}-gdc but
				# that breaks checks like `if(basename(DC) == gdc)` which seem to
				# be quite common. For this reason keep the basename gdc.
				debug-print "${FUNCNAME}: DC = ${DC}"
				;;
			DMDW)
				export DMDW=$(
					_dlang_echo_implementation_string \
						"${impl}" \
						"${EPREFIX}/usr/lib/dmd/${impl#dmd-}/bin/dmd" \
						"${EPREFIX}/usr/${CHOST_default}/gcc-bin/${impl#gdc-}/gdmd" \
						"${EPREFIX}/usr/lib/ldc2/${impl#ldc2-}/bin/ldmd2"
					   )
				# Same observation about ${CHOST}-gdmd as above.
				debug-print "${FUNCNAME}: DMDW = ${DMDW}"
				;;
			DLANG_LIBDIR)
				# There are two supported use cases for dlang packages:
				# no-multilib profile and amd64/x86 multilib.
				pick_nomulti_amd64_x86() {
					if ! has_multilib_profile; then
						echo "${1}"
					else
						case "${ABI}" in
							amd64*) echo "${2}" ;;
							x86*) echo "${3}" ;;
							*)
								eerror "ABI ${ABI} is not supported in a multilib configuration."
								die "Multilib abi is not x86/amd64!"
						esac
					fi
				}

				local libdirname
				case "${impl::3}" in
					ldc)
						if ver_test "${impl#ldc2-}" -ge 1.40; then
							# ldc started using multilib-build for the runtime
							libdirname="$(get_libdir)"
						else
							# Old dlang.eclass always picked lib<bits> which
							# isn't always correct. The proper calculation
							# is found in runtime/CMakeLists.txt which is:
							# - native abi is always put in lib<LIB_SUFFIX>
							#   which is set by cmake.eclass to $(get_libdir)
							# - x86 on amd64 is put in lib<bits>
							libdirname=$(pick_nomulti_amd64_x86 \
											 "$(get_libdir)" "$(get_libdir)" "lib32")
						fi
						;;
					gdc)
						# I have no idea how gcc does it but the line
						# below gives the correct result, probably.
						libdirname=$(pick_nomulti_amd64_x86 "" "" "/32")
						;;
					dmd)
						# Wonderful old dmd. It only supports x86 and
						# amd64 so we only have to consider these two
						# arches, either independently or multilib.
						#
						# The logic is controlled by us so the calculation
						# is found in dlang.eclass. Just copy it here, mostly.
						# Simplify the ABI usage a little.
						[[ ${ABI} == @(x86|amd64) ]] ||
							die "Unknown ABI ${ABI} for dmd implementation."
						local model=$(dlang_get_abi_bits)

						if has_multilib_profile || [[ ${model} == 64 ]]; then
							libdirname=lib${model}
						else
							libdirname=lib
						fi
						;;
				esac

				export DLANG_LIBDIR=$(
					_dlang_echo_implementation_string \
						"${impl}" \
						"lib/dmd/${impl#dmd-}/" \
						"lib/gcc/${CHOST_default}/${impl#gdc-}" \
						"lib/ldc2/${impl#ldc2-}/"
					   )${libdirname}
				debug-print "${FUNCNAME}: DLANG_LIBDIR = ${DLANG_LIBDIR}"
				;;
			DLANG_IMPORT_DIR)
				# This is the only variable which is treated
				# differently. Since it doesn't depend on <impl> we want
				# to allow setting its value even if $EDC is unset.
				export DLANG_IMPORT_DIR="$(dlang_get_import_dir)"
				debug-print "${FUNCNAME}: DLANG_IMPORT_DIR = ${DLANG_IMPORT_DIR}"
				;;
			DLANG_MODEL_FLAG)
				if has_multilib_profile; then
					# Only x86/amd64 multilib is supported
					[[ ${ABI} == @(x86|amd64) ]] ||
						die "ABI ${ABI} is not supported in a multilib configuration."
					DLANG_MODEL_FLAG=-m$(dlang_get_abi_bits)
				else
					DLANG_MODEL_FLAG=
				fi
				export DLANG_MODEL_FLAG
				debug-print "${FUNCNAME}: DLANG_MODEL_FLAG = ${DLANG_MODEL_FLAG}"
				;;
			DCFLAGS)
				# Old dlang.eclass added -op (do not strip paths from
				# source files) to LDCFLAGS. This doesn't seem like
				# something that should be toggled unconditionally so it
				# is not added here.
				#
				# Changes in the behavior of packages with this flag
				# enabled I've observed in dev-lang/ldc2 where a regex
				# match gets messed up though there don't seem to be any
				# relevant consequences (observe the `Host D compiler
				# linker args' config line).
				#
				# The old eclass added -shared-libphobos to
				# GDCFLAGS. This is quite important but, since it a flag
				# that affects linking, it has been moved to DLANG_LDFLAGS.
				export DCFLAGS=$(
					_dlang_echo_implementation_string \
						"${impl}" "${DMDFLAGS}" "${GDCFLAGS}" "${LDCFLAGS}")
				debug-print "${FUNCNAME}: DCFLAGS = ${DCFLAGS}"
				;;
			DMDW_DCFLAGS)
				# Don't copy the logic from above, just re-call.
				local DCFLAGS
				_dlang_export "${impl}" DCFLAGS
				case "${impl}" in
					# dmd understands his own flags and ldmd2 passes
					# through unknown flags to ldc2.
					dmd*|ldc*) DMDW_DCFLAGS="${DCFLAGS}" ;;
					gdc*)
						local flags=( ${DCFLAGS} )
						if [[ ${flags[*]} == *,* ]]; then
						eerror "gdc-style flags can not be converted to gdmd-style"
						eerror "because they contain a comma: ${flags[*]}"

						die 'flags contain a nonconvertible comma.'
					fi
					# `-arg1' `-arg2' => `-q,-arg1' `-q,-arg2'
					DMDW_DCFLAGS="${flags[@]/#/-q,}"
					;;
				esac
				export DMDW_DCFLAGS
				debug-print "${FUNCNAME}: DMDW_DCFLAGS = ${DMDW_DCFLAGS}"
				;;
			DLANG_LDFLAGS)
				# In case some $LDFLAGS fail with some Dlang
				# implementations this is where they should be
				# stripped. Out of the old eclass:
				#
				# --gc-sections, fails until dmd-2.072
				#
				# --icf= still has an open bug but I can't reproduce it
				# so I won't remove it. I've tested building dub with
				# -L--icf=safe with both ld.gold and ld.lld, static and
				# dynamic phobos. The old eclass only removed it for dmd.
				# See: https://issues.dlang.org/show_bug.cgi?id=17515
				#
				# Very important, add -shared-libphobos for gdc. It
				# _will_ be linked statically otherwise.
				case "${impl::3}" in
					dmd|ldc)
						# Old dlang.eclass picked -L for dmd and -L= for
						# ldc2. Meson doesn't like -L= however so we go
						# with -L for both. See:
						# 391ce890a1ca37cce3ee643f61c63c06f428d0dc
						local prefix=-L

						# Convert -Wl arguments
						local flags=() flag
						for flag in ${LDFLAGS}; do
							if [[ ${flag::4} == -Wl, ]]; then
								# -Wl,a,b,c -> -La -Lb -Lc
								flag="${prefix}${flag#-Wl,}" # flag="-La,b,c"
								flag="${flag//,/ ${prefix}}" # flag="-La -Lb -Lc"
							fi
							flags+=( "${flag}" )
						done
						DLANG_LDFLAGS="${flags[*]}"

						# Then convert -Xlinker

						# This substitution can fail if there is more
						# than one space. It's better than the old eclass which
						# didn't do it at all (though it tried to).
						DLANG_LDFLAGS="${DLANG_LDFLAGS//-Xlinker /${prefix}}"
						;;
					gdc)
						DLANG_LDFLAGS="${LDFLAGS} -shared-libphobos"
						;;
				esac
				export DLANG_LDFLAGS
				debug-print "${FUNCNAME}: DLANG_LDFLAGS = ${DLANG_LDFLAGS}"
				;;
			DLANG_DMDW_LDFLAGS)
				# It would be very easy if we could go like in
				# DMDW_DCFLAGS and just insert some -q, for gdc. The
				# problem is $LDFLAGS typically contain commas (-Wl,-O1)
				# so that solution is busted.  Because of this we have
				# to do an actual conversions.
				#
				# But a dmd wrapper is close enough to a dmd
				# implementation so the logic from DLANG_LDFLAGS should
				# suffice, in this case at least.
				local DLANG_LDFLAGS
				case "${impl::3}" in
					dmd|ldc) _dlang_export "${impl}" DLANG_LDFLAGS ;;
					gdc)
						_dlang_export "dmd-wrap-${impl}" DLANG_LDFLAGS
						# Do not forget the very important flag
						DLANG_LDFLAGS+=" -q,-shared-libphobos"
						;;
				esac
				export DLANG_DMDW_LDFLAGS=${DLANG_LDFLAGS}
				debug-print "${FUNCNAME}: DLANG_DMDW_LDFLAGS = ${DLANG_DMDW_LDFLAGS}"
				;;
			DLANG_DEBUG_FLAG)
				export DLANG_DEBUG_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-debug" "-fdebug" "-d-debug")
				debug-print "${FUNCNAME}: DLANG_DEBUG_FLAG = ${DLANG_DEBUG_FLAG}"
				;;
			DLANG_LINKER_FLAG)
				export DLANG_LINKER_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-L" "-Wl," "-L")
				debug-print "${FUNCNAME}: DLANG_LINKER_FLAG = ${DLANG_LINKER_FLAG}"
				;;
			DLANG_MAIN_FLAG)
				export DLANG_MAIN_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-main" "-fmain" "-main")
				debug-print "${FUNCNAME}: DLANG_MAIN_FLAG = ${DLANG_MAIN_FLAG}"
				;;
			DLANG_OUTPUT_FLAG)
				export DLANG_OUTPUT_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-of" "-o" "-of=")
				debug-print "${FUNCNAME}: DLANG_OUTPUT_FLAG = ${DLANG_OUTPUT_FLAG}"
				;;
			DLANG_UNITTEST_FLAG)
				export DLANG_UNITTEST_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-unittest" "-funittest" "-unittest")
				debug-print "${FUNCNAME}: DLANG_UNITTEST_FLAG = ${DLANG_UNITTEST_FLAG}"
				;;
			DLANG_VERSION_FLAG)
				export DLANG_VERSION_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-version" "-fversion" "-d-version")
				debug-print "${FUNCNAME}: DLANG_VERSION_FLAG = ${DLANG_VERSION_FLAG}"
				;;
			DLANG_FE_VERSION)
				local implDetails=( $(_dlang_get_impl_details "${impl}") )
				export DLANG_FE_VERSION=${implDetails[1]}
				debug-print "${FUNCNAME}: DLANG_FE_VERSION = ${DLANG_FE_VERSION}"
				;;
			DLANG_BE_VERSION)
				export DLANG_BE_VERSION=${impl#*-}
				debug-print "${FUNCNAME}: DLANG_BE_VERSION = ${DLANG_BE_VERSION}"
				;;
			DLANG_WNO_ERROR_FLAG)
				export DLANG_WNO_ERROR_FLAG=$(
					_dlang_echo_implementation_string \
						"${impl}" "-wi" "-Wno-error" "--wi")
				debug-print "${FUNCNAME}: DLANG_WNO_ERROR_FLAG = ${DLANG_WNO_ERROR_FLAG}"
				;;
			DLANG_SYSTEM_IMPORT_PATHS)
				# Basically copy the output of each compiler when they
				# can't find a module.
				#
				# Right now there's only 1 path for each implementation
				# but if there were more they need to be separated by
				# \n.
				#
				# Old dlang.eclass added include/d/ldc for ldc2 but that
				# doesn't make much sense as the compiler can't import
				# the modules in that folder by default. Since the only
				# consumer of this variable is dcd which is used for
				# autocompletion it's better to go with the rationale
				# above, i.e. whatever the compiler finds by default.
				export DLANG_SYSTEM_IMPORT_PATHS=$(
					_dlang_echo_implementation_string \
						"${impl}" \
						"${EPREFIX}/usr/lib/dmd/${impl#dmd-}/import" \
						"${EPREFIX}/usr/lib/gcc/${CHOST_default}/${impl#gdc-}/include/d" \
						"${EPREFIX}/usr/lib/ldc2/${impl#ldc2-}/include/d"
					   )

				debug-print "${FUNCNAME}: DLANG_SYSTEM_IMPORT_PATHS = ${DLANG_SYSTEM_IMPORT_PATHS}"
				;;
			DLANG_PKG_DEP)
				_dlang_check_DLANG_REQ_USE
				local usedep=${DLANG_REQ_USE[${impl%-*}]}
				if [[ ${usedep} ]]; then
					usedep=$(
						_dlang_echo_implementation_string \
							"${impl}" "[${usedep}]" "[d,${usedep}]" "[${usedep}]")
				else
					usedep=$(
						_dlang_echo_implementation_string \
							"${impl}" "" "[d]" "")
				fi

				# The eclass guarantees both a Dlang compiler and a dmd
				# wrapper of said compiler. ldmd2 comes with
				# dev-lang/ldc2 but gdmd has to be installed separately.
				#
				# dmd and ldc2 should have ABI compatible patch releases
				# but we will use :slot= just in case.
				#
				# Since ldc2-1.40.0 the package is split into compiler +
				# runtime. Since only the runtime provides relevant USE
				# flags usedep is only applied to it.
				local dmd_dep="dev-lang/dmd:${impl#dmd-}=${usedep}"
				local gdc_dep="sys-devel/gcc:${impl#gdc-}${usedep} dev-util/gdmd:${impl#gdc-}"
				local ldc_ver="${impl#ldc2-}" ldc_dep
				if [[ ${impl} == ldc2* ]] && ver_test "${ldc_ver}" -ge 1.40; then
					ldc_dep="dev-lang/ldc2:${ldc_ver} dev-libs/ldc2-runtime:${ldc_ver}=${usedep}"
				else
					ldc_dep="dev-lang/ldc2:${ldc_ver}=${usedep}"
				fi

				export DLANG_PKG_DEP=$(
					_dlang_echo_implementation_string \
						"${impl}" "${dmd_dep}" "${gdc_dep}" "${ldc_dep}"
					)
				debug-print "${FUNCNAME}: DLANG_PKG_DEP = ${DLANG_PKG_DEP}"
				;;
			*)
				die "_dlang_export: unknown variable ${var}"
		esac
	done
}

# @FUNCTION: _dlang_wrapper_setup
# @USAGE: [<path> [<impl>]]
# @INTERNAL
# @DESCRIPTION:
# Create proper dlang executable setup and pkg-config wrapper (if
# available) in the directory named by <path>. Set up PATH and
# PKG_CONFIG_PATH appropriately. <path> defaults to ${T}/${EDC}.
#
# The wrappers will be created for implementation named by <impl>, or
# for one named by ${EDC} if no <impl> is passed.
#
# If the named directory contains a mark file, it will be assumed to
# contain proper wrappers already and only environment setup will be
# done. If wrapper update is requested, the directory shall be removed
# first.
#
# It is important to note that this function uses $DLANG_LIBDIR which
# uses $ABI to be calculated. Make sure that $ABI is set properly
# _before_ this function is called otherwise wrong variables will be
# generated.
_dlang_wrapper_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	local workdir=${1:-${T}/${EDC}}
	local impl=${2:-${EDC}}

	[[ ${workdir} ]] || die "${FUNCNAME}: no workdir specified."
	[[ ${impl} ]] || die "${FUNCNAME}: no impl nor EDC specified."

	local compiler=${impl%-*}

	if [[ ! -x ${workdir}/.dlang_marked ]]; then
		mkdir -p "${workdir}" || die
		touch "${workdir}"/.dlang_marked || die

		mkdir -p "${workdir}"/bin || die

		# Clean up, in case we were supposed to do a cheap update. We
		# have to remove any previous compilers, so no use but to glob.
		# We can be more specific, by doing dmd*, ldc2*, gdc* but that's
		# too many lines.
		rm -f "${workdir}"/bin/* || die
		rm -f "${workdir}"/pkgconfig || die

		local EDC DC DLANG_LIBDIR
		_dlang_export "${impl}" EDC DC DLANG_LIBDIR

		# Dlang compiler
		ln -s "${DC}" "${workdir}/bin/${compiler}" || die
		# pkg-config, this may create a broken symlink
		ln -s "${EPREFIX}/usr/${DLANG_LIBDIR}/pkgconfig" "${workdir}"/pkgconfig || die

		# dmd and ldc2 use $CC to link so specify it.
		tc-export CC
		# With dmd $CC is split by spaces, with ldc it is not. See:
		# https://github.com/ldc-developers/ldc/pull/4582. We can solve
		# this by:
		if [[ ${CC} == *' '* ]]; then
			# Only make a script if $CC differs from itself when it is
			# expanded.
			cat > "${workdir}/bin/${CC}" <<EOF
#!/bin/sh
exec ${CC} "\${@}"
EOF
			chmod +x "${workdir}/bin/${CC}"
			# which creates a script that properly expands $CC that will
			# be called when ldc2 tries to link stuff. This is better
			# than the old eclass which disregarded this value.
		fi
	fi

	# Now, set the environment.
	# But note that ${workdir} may be shared with something else,
	# and thus already on top of PATH.
	if [[ ${PATH##:*} != ${workdir}/bin ]]; then
		PATH=${workdir}/bin${PATH:+:${PATH}}
	fi
	if [[ ${PKG_CONFIG_PATH##:*} != ${workdir/pkgconfig} ]]; then
		PKG_CONFIG_PATH=${workdir}/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}
	fi

	export PATH PKG_CONFIG_PATH
}

# @FUNCTION: _dlang_compile_extra_flags
# @INTERNAL
# @DESCRIPTION:
# Generate and echo implementation dependent compiler arguments for:
#
# - import directories, specified by $imports
#
# - string import directories, specified by $string_imports
#
# - version to enable, specified by $versions
#
# - libraries to link, specified by $libs
#
# The implementation is taken from ${EDC}.
_dlang_compile_extra_flags() {
	debug-print-function ${FUNCNAME} "${@}"

	local imports=( ${imports} )
	local simports=( ${string_imports} )
	local versions=( ${versions} )
	local libs=( ${libs} )

	debug-print "${FUNCNAME}: imports: ${imports[*]}"
	debug-print "${FUNCNAME}: simports: ${simports[*]}"
	debug-print "${FUNCNAME}: versions: ${versions[*]}"
	debug-print "${FUNCNAME}: libs: ${libs[*]}"

	local DLANG_VERSION_FLAG DLANG_LINKER_FLAG
	_dlang_export DLANG_VERSION_FLAG DLANG_LINKER_FLAG

	# Just like old dlang.eclass, though maybe ldc2 can use -I and -J
	local import_prefix simport_prefix
	case "${EDC::3}" in
		dmd|gdc)
			import_prefix=-I
			simport_prefix=-J
			;;
		ldc)
			import_prefix=-I=
			simport_prefix=-J=
			;;
	esac

	echo \
		"${imports[@]/#/${import_prefix}}" \
		"${simports[@]/#/${simport_prefix}}" \
		"${versions[@]/#/${DLANG_VERSION_FLAG}=}" \
		"${libs[@]/#/${DLANG_LINKER_FLAG}-l}"
}

# @FUNCTION: _dlang_echo_implementation_string
# @USAGE: <impl> <if-dmd> <if-gdc> <if-ldc2>
# @INTERNAL
# @DESCRIPTION:
# Based on an implementation, echo one of the parameters.
_dlang_echo_implementation_string() {
	debug-print-function ${FUNCNAME} "${@}"

	case "${1::3}" in
		dmd) echo "${2}" ;;
		gdc) echo "${3}" ;;
		ldc) echo "${4}" ;;
		*) die "Unknown implementation: ${1}." ;;
	esac
}

# @FUNCTION: _dlang_check_DLANG_REQ_USE
# @INTERNAL
# @DESCRIPTION:
# Check the $DLANG_REQ_USE variable and make sure it's in the correct
# format.
#
# More precisely, check that it's an associative array and that it only
# contains the keys: "dmd", "gdc", or "ldc2".
_dlang_check_DLANG_REQ_USE() {
	debug-print-function ${FUNCNAME} "${@}"

	! declare -p DLANG_REQ_USE &>/dev/null && return
	[[ ${DLANG_REQ_USE@a} != *A* ]] && die "DLANG_REQ_USE must be an associative array!"

	local key
	for key in "${!DLANG_REQ_USE[@]}"; do
		case "${key}" in
			dmd|gdc|ldc2) ;;
			ldc) die "Unknown key ${key} in DLANG_REQ_USE, perhaps you meant ldc2?" ;;
			*) die "Unknown key ${key} in DLANG_REQ_USE!" ;;
		esac
	done
}

# @FUNCTION: _dlang_impl_matches
# @USAGE: <impl> [<pattern>...]
# @INTERNAL
# @DESCRIPTION:
# Check whether the specified <impl> matches at least one of the
# patterns following it. Return 0 if it does, 1 otherwise. Matches
# if no patterns are provided.
#
# <impl> can be in DLANG_COMPAT or EDC form. The patterns can
# either be fnmatch-style or frontend versions, e.g "2.100".
_dlang_impl_matches() {
	[[ ${#} -ge 1 ]] || die "${FUNCNAME}: takes at least 1 parameter"
	[[ ${#} -eq 1 ]] && return 0

	local impl=${1/./_} pattern
	shift

	for pattern; do
		case ${pattern} in
			2.[0-9][0-9][0-9])
				local DLANG_FE_VERSION
				_dlang_export "${impl}" DLANG_FE_VERSION
				[[ ${pattern} == ${DLANG_FE_VERSION} ]] && return 0
				;;
			*)
				# unify value style to allow lax matching
				[[ ${impl} == ${pattern/./_} ]] && return 0
				;;
		esac
	done

	return 1

}

# @FUNCTION: _dlang_verify_patterns
# @USAGE: <pattern>...
# @INTERNAL
# @DESCRIPTION:
# Verify whether the patterns passed to the eclass function are correct
# (i.e. can match any valid implementation).  Dies on wrong pattern.
_dlang_verify_patterns() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl pattern
	for pattern; do
		case ${pattern} in
			# Only check for versions as they appear in
			# _DLANG_*_FRONTENDS, not in _DLANG_HISTORICAL_IMPLS.
			2.10[01234567])
				continue
				;;
		esac

		for impl in "${_DLANG_ALL_IMPLS[@]}" "${_DLANG_HISTORICAL_IMPLS[@]}"
		do
			[[ ${impl} == ${pattern/./_} ]] && continue 2
		done

		die "Invalid implementation pattern: ${pattern}"
	done
}

fi
