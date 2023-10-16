# @ECLASS: dlang.eclass
# @MAINTAINER:
# Marco Leise <marco.leise@gmx.de>
# @BLURB: install D libraries in multiple locations for each D version and compiler
# @DESCRIPTION:
# The dlang eclass faciliates creating dependiencies on D libraries for use
# with different D compilers and D versions.
# DLANG_VERSION_RANGE can be set in the ebuild to limit the search on the known
# compatible Dlang front-end versions. It is a space separated list with each item
# can be a single version, an open or a closed range (e.g. "2.063 2.065-2.067 2.070-").
# The range can be open in either direction.
# DLANG_PACKAGE_TYPE determines whether the current ebuild can be compiled for
# multiple Dlang compilers (i.e. is a library to be installed for different
# versions of dmd, gdc or ldc2) or a single compiler (i.e. is an application).
# "single" - An application is built and the package will be built using one compiler.
# "multi" - A library is built and multiple compiler versions and vendors can be selected.
# "dmd" - Special case for dmd, which is like "single", but picking no compiler USE flag
#         is allowed and results in a self-hosting dmd.
# DLANG_USE_COMPILER, if set, inhibits the generation of IUSE, REQUIRED_USE, DEPEND
# and RDEPEND for Dlang compilers based on above variables. The ebuild is responsible
# for providing them as required by the function it uses from this eclass.

# @ECLASS_VARIABLE: DLANG_COMPILER_USE
# @DESCRIPTION:
# Holds the active Dlang compiler for an application as a USE flag to be passed on to depencencies (libraries).
# Using this variable one can ensure that all required libraries must be compiled with the same compiler.

# @ECLASS_VARIABLE: DLANG_IMPORT_DIR
# @DESCRIPTION:
# The path that is used to install include files. A sub-directory specific to the package should be used.

if [[ ${_ECLASS_ONCE_DLANG} != "recur -_+^+_- spank" ]] ; then
_ECLASS_ONCE_DLANG="recur -_+^+_- spank"

if has ${EAPI:-0} 0 1 2 3 4 5; then
	die "EAPI must be >= 6 for dlang packages."
fi

inherit flag-o-matic dlang-compilers
test ${EAPI:-0} -lt 7 && inherit eapi7-ver
if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]]; then
	# We handle a multi instance package.
	inherit multilib-minimal
fi

EXPORT_FUNCTIONS src_prepare src_configure src_compile src_test src_install

# Definition of know compilers and supported front-end versions from dlang-compilers.eclass
dlang-compilers_declare_versions

# @FUNCTION: dlang_foreach_config
# @DESCRIPTION:
# Function that calls its arguments for each D configuration. A few environment
# variables will be set for each call:
# ABI: See 'multilib_get_enabled_abis' from multilib-build.eclass.
# MODEL: This is either 32 or 64.
# DLANG_VENDOR: Either DigitalMars, GNU or LDC.
# DC: D compiler command. E.g.
#   /usr/x86_64-pc-linux-gnu/gcc-bin/12/x86_64-pc-linux-gnu-gdc,
#   /usr/lib/dmd/2.067/bin/dmd, or
#   /usr/lib/ldc2/0.17/bin/ldc2
# DMD: DMD compiler command. E.g.
#   /usr/x86_64-pc-linux-gnu/gcc-bin/12/x86_64-pc-linux-gnu-gdmd,
#   /usr/lib/dmd/2.086/bin/dmd, or
#   /usr/lib/ldc2/0.17/bin/ldmd2
# DC_VERSION: Release version of the compiler. This is the version excluding any
#   Patch releases. So dmd 2.064.2 would still be 2.064. This version is used
#   to separate potentially incompatible ABIs and to create the library path.
#   Typical versions of gdc or ldc are 4.8.1 or 0.12.
# DLANG_VERSION: This differs from DC_VERSION in so far as it displays the
#   front-end or language specification version for every compiler. Since the
#   release of D1 it follows the scheme x.yyy and is as of writing at 2.064.
# DLANG_LINKER_FLAG: The command-line flag, the respective compiler understands
#   as a prefix for a single argument that should be passed to the linker.
#   dmd: -L, gdc: -Xlinker, ldc: -L=
# DLANG_LIB_DIR: The compiler and compiler version specific library directory.
dlang_foreach_config() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=($(_dlang_build_configurations))

	multibuild_wrapper() {
		debug-print-function ${FUNCNAME} "${@}"

		# We need to reset CC, else when dmd calls it, the result is:
		# "x86_64-pc-linux-gnu-gcc -m32": No such file or directory
		if [[ -v CC ]]; then
			local _ORIGINAL_CC="${CC}"
		fi
		multilib_toolchain_setup "${ABI}"
		if [[ -v _ORIGINAL_CC ]]; then
			CC="${_ORIGINAL_CC}"
		else
			unset CC
		fi
		mkdir -p "${BUILD_DIR}" || die
		pushd "${BUILD_DIR}" >/dev/null || die
		_dlang_use_build_vars "${@}"
		popd >/dev/null || die
	}

	multibuild_foreach_variant multibuild_wrapper "${@}"
}

# @FUNCTION: dlang_single_config
# @DESCRIPTION:
# Wrapper for build phases when only a single build configuraion is used. See `dlang_foreach_config()` for more details.
dlang_single_config() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANT=$(_dlang_build_configurations)

	_dlang_use_build_vars "${@}"
}

export DLANG_IMPORT_DIR="usr/include/dlang"

# @FUNCTION: dlang_src_prepare
# @DESCRIPTION:
# Create a single copy of the package sources for each enabled D configuration.
dlang_src_prepare() {
	debug-print-function ${FUNCNAME} "${@}"

	default_src_prepare

	if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]]; then
		local MULTIBUILD_VARIANTS=($(_dlang_build_configurations))
		multibuild_copy_sources
	fi
}

dlang_src_configure() {
	_dlang_phase_wrapper configure
}

dlang_src_compile() {
	_dlang_phase_wrapper compile
}

dlang_src_test() {
	_dlang_phase_wrapper test
}

dlang_src_install() {
	_dlang_phase_wrapper install
}

# @FUNCTION: dlang_exec
# @DESCRIPTION:
# Run and print a shell command. Aborts the ebuild on error using "die".
dlang_exec() {
	echo "${@}"
	${@} || die
}

# @FUNCTION: dlang_compile_bin
# @DESCRIPTION:
# Compiles a D application. The first argument is the output file name, the
# other arguments are source files. Additional variables can be set to fine tune
# the compilation. They will be prepended with the proper flags for each
# compiler:
# versions - a list of versions to activate during compilation
# imports - a list of import paths
# string_imports - a list of string import paths
#
# Aditionally, if the ebuild offers the "debug" use flag, we will automatically
# raise the debug level to 1 during compilation.
dlang_compile_bin() {
	[[ "${DLANG_PACKAGE_TYPE}" == "multi" ]] && die "${FUNCTION} does not work with DLANG_PACKAGE_TYPE=\"multi\" currently."

	local binname="${1}"
	local sources="${@:2}"

	dlang_exec ${DC} ${DCFLAGS} ${sources} $(_dlang_additional_flags) \
		${LDFLAGS} ${DLANG_OUTPUT_FLAG}${binname}
}

# @FUNCTION: dlang_compile_lib_a
# @DESCRIPTION:
# Compiles a D static library. The first argument is the output file name, the
# other arguments are source files. Additional variables and the
# "debug" use flag will be handled as described in dlang_compile_bin().
dlang_compile_lib_a() {
	local libname="${1}"
	local sources="${@:2}"

	if [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		die "Static libraries for GDC is not supported yet."
	fi
	if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]]; then
		DCFLAGS="${DCFLAGS} -m${MODEL}"
	fi
	dlang_exec ${DC} ${DCFLAGS} ${sources} $(_dlang_additional_flags) \
		${LDFLAGS} ${DLANG_A_FLAGS} ${DLANG_OUTPUT_FLAG}${libname}
}

# @FUNCTION: dlang_compile_lib_so
# @DESCRIPTION:
# Compiles a D shared library. The first argument is the output file name, the
# second argument is the soname (typically file name without patch level
# suffix), the other arguments are source files. Additional variables and the
# "debug" use flag will be handled as described in dlang_compile_bin().
dlang_compile_lib_so() {
	local libname="${1}"
	local soname="${2}"
	local sources="${@:3}"

	dlang_exec ${DC} ${DCFLAGS} -m${MODEL} ${sources} $(_dlang_additional_flags) \
		${LDFLAGS} ${DLANG_SO_FLAGS} ${DLANG_LINKER_FLAG}-soname=${soname} \
		${DLANG_OUTPUT_FLAG}${libname}
}

# @FUNCTION: dlang_convert_ldflags
# @DESCRIPTION:
# Makes linker flags meant for GCC understandable for the current D compiler.
# Basically it replaces -L with what the D compiler uses as linker prefix.
dlang_convert_ldflags() {
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]] || [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		local set prefix flags=()
		if [[ is_dmd ]]; then
			prefix="-L"
		elif [[ is_ldc ]]; then
			prefix="-L="
		fi
		for set in ${LDFLAGS}; do
			if [[ "${set:0:4}" == "-Wl," ]]; then
				set=${set/-Wl,/${prefix}}
				flags+=(${set//,/ ${prefix}})
			elif [[ "${set:0:9}" == "-Xlinker " ]]; then
				flags+=(${set/-Xlinker /${prefix}})
			elif [[ "${set:0:2}" == "-L" ]]; then
				flags+=(${set/-L/${prefix}})
			else
				flags+=(${set})
			fi
		done
		echo "${flags[@]}"
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		echo "${LDFLAGS}"
	else
		die "Set DLANG_VENDOR to DigitalMars, LDC or GNU prior to calling ${FUNCNAME}()."
	fi
}

# @FUNCTION: dlang_dmdw_dcflags
# @DESCRIPTION:
# Convertes compiler specific $DCFLAGS to something that can be passed to the
# dmd wrapper of said compiler. Calls `die` if the flags could not be
# converted.
dlang_dmdw_dcflags() {
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		# There's no translation that needs to be done.
		echo "${DCFLAGS}"
	elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		# ldmd2 passes all the arguments that it doesn't understand to ldc2.
		echo "${DCFLAGS}"
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		# From `gdmd --help`:   -q,arg1,...    pass arg1, arg2, etc. to gdc
		if [[ "${DCFLAGS}" =~ .*,.* ]]; then
			eerror "DCFLAGS (${DCFLAGS}) contain a comma and can not be passed to gdmd."
			eerror "Please remove the comma, use a different compiler, or call gdc directly."
			die "DCFLAGS contain an unconvertable comma."
		fi

		local set flags=()
		for set in ${DCFLAGS}; do
			flags+=("-q,${set}")
		done
		echo "${flags[@]}"
	else
		die "Set DLANG_VENDOR to DigitalMars, LDC or GNU prior to calling ${FUNCNAME}()."
	fi
}

# @FUNCTION: dlang_system_imports
# @DESCRIPTION:
# Returns a list of standard system import paths (one per line) for the current
# D compiler. This includes druntime and Phobos as well as compiler specific
# paths.
dlang_system_imports() {
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		echo "/usr/lib/dmd/${DC_VERSION}/import"
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		# gcc's SLOT is its major version component.
		echo "/usr/lib/gcc/${CHOST_default}/${DC_VERSION}/include/d"
	elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		echo "/usr/lib/ldc2/${DC_VERSION}/include/d"
		echo "/usr/lib/ldc2/${DC_VERSION}/include/d/ldc"
	else
		die "Could not detect D compiler vendor!"
	fi
}

# @FUNCTION: dlang_phobos_level
# @DESCRIPTION:
# Succeeds if we are compiling against a version of Phobos that is at least as
# high as the argument.
dlang_phobos_level() {
	if [ -z "$DLANG_VERSION" ]; then
		[ "$DLANG_PACKAGE_TYPE" != "multi" ] || die "'dlang_phobos_level' needs 'DLANG_PACKAGE_TYPE != multi' when called outside of compiles."
		local config=`_dlang_build_configurations`
		local dc="$(echo ${config} | cut -d- -f2)"
		local dc_version="$(echo ${config} | cut -d- -f3)"
		local DLANG_VERSION="$(_dlang_compiler_to_dlang_version ${dc} ${dc_version})"
	fi
	ver_test "$DLANG_VERSION" -ge "$1"
}

### Non-public helper functions ###

declare -a _dlang_compiler_iuse
declare -a _dlang_compiler_iuse_mask
declare -a _dlang_depends

# @FUNCTION: _dlang_compiler_masked_archs_for_version_range
# @DESCRIPTION:
# Given a Dlang compiler represented through an IUSE flag (e.g. "ldc2-1_1")
# and DEPEND atom (e.g. "dev-lang/ldc2:1.1="), this function tests if the
# current ebuild can depend and thus be compiled with that compiler on
# one or more architectures.
# A compiler that is less stable than the current ebuild for all
# architectures, is dropped completely. A compiler that disqualifies
# for only some, but not all architectures, on the other hand, is disabled
# though REQUIRED_USE (e.g. "!amd64? ( ldc2-1_1? ( dev-lang/ldc2:1.1= ) )").
# Available compilers are accumulated in the _dlang_compiler_iuse array,
# which is later turned into the IUSE variable.
# Partially available compilers are additionally masked out for particular
# architectures by adding them to the _dlang_compiler_iuse_mask array,
# which is later appended to REQUIRED_USE.
# Finally, the _dlang_depends array receives the USE-flag enabled
# dependencies on Dlang compilers, which is later turned into DEPEND and
# RDEPEND.
_dlang_compiler_masked_archs_for_version_range() {
	local iuse=$1
	if [[ "$iuse" == gdc* ]]; then
		local depend="$iuse? ( $2 dev-util/gdmd:${iuse#gdc-} )"
	else
		local depend="$iuse? ( $2 )"
	fi
	local dlang_version=${3%% *}
	local compiler_keywords=${3:${#dlang_version}}
	local compiler_keyword package_keyword arch
	local -a masked_archs

	# Check the version range
	if [[ -n "$4" ]]; then
		[[ $((10#${dlang_version#*.})) -lt $((10#${4#*.})) ]] && return 1
	fi
	if [[ -n "$5" ]]; then
		[[ $((10#${dlang_version#*.})) -gt $((10#${5#*.})) ]] && return 1
	fi

	# Check the stability requirements
	local package_stab comp_stab=0 have_one=0
	for package_keyword in $KEYWORDS; do
		if [ "${package_keyword:0:1}" == "-" ]; then
			# Skip "-arch" and "-*"
			continue
		elif [ "${package_keyword:0:1}" == "~" ]; then
			package_stab=1
			arch=${package_keyword:1}
		else
			package_stab=2
			arch=$package_keyword
		fi

		comp_stab=0
		for compiler_keyword in $compiler_keywords; do
			if [ "$compiler_keyword" == "~$arch" ]; then
				comp_stab=1
			elif [ "$compiler_keyword" == "$arch" ]; then
				comp_stab=2
			fi
		done
		if [ $comp_stab -lt $package_stab ]; then
			masked_archs+=( $arch )
		fi
		if [ $comp_stab -gt 0 ]; then
			have_one=1
		fi
	done
	[ $have_one -eq 0 ] && return 1

	_dlang_compiler_iuse+=( $iuse )
	if [ "${#masked_archs[@]}" -ne 0 ]; then
		for arch in ${masked_archs[@]}; do
			_dlang_compiler_iuse_mask+=( "${arch}? ( !${iuse} )" )
			depend="!${arch}? ( ${depend} )"
		done
	fi
	_dlang_depends+=( "$depend" )
}

# @FUNCTION: _dlang_filter_compilers
# @DESCRIPTION:
# Given a range of Dlang front-end version that the current ebuild can be built with, this function goes through each
# compatible Dlang compilers as provided by the file dlang-compilers.eclass and then calls
# _dlang_compiler_masked_archs_for_version_range where they will be further scrutinized for architecture stability
# requirements and then either dropped as option or partially masked.
_dlang_filter_compilers() {
	local dc_version mapping iuse depend

	# filter for DMD (hardcoding support for x86 and amd64 only)
	for dc_version in "${!_dlang_dmd_frontend[@]}"; do
		mapping="${_dlang_dmd_frontend[${dc_version}]}"
		iuse="dmd-$(ver_rs 1- _ $dc_version)"
		if [ "${DLANG_PACKAGE_TYPE}" == "multi" ]; then
			depend="[${MULTILIB_USEDEP}]"
		else
			depend=""
		fi
		depend="dev-lang/dmd:$dc_version=$depend"
		_dlang_compiler_masked_archs_for_version_range "$iuse" "$depend" "$mapping" "$1" "$2"
	done

	# GDC (doesn't support sub-slots, to stay compatible with upstream GCC)
	for dc_version in "${!_dlang_gdc_frontend[@]}"; do
		mapping="${_dlang_gdc_frontend[${dc_version}]}"
		iuse="gdc-${dc_version}"
		depend="sys-devel/gcc:$dc_version[d,-d-bootstrap(-)]"
		_dlang_compiler_masked_archs_for_version_range "$iuse" "$depend" "$mapping" "$1" "$2"
	done

	# filter for LDC2
	for dc_version in "${!_dlang_ldc2_frontend[@]}"; do
		mapping="${_dlang_ldc2_frontend[${dc_version}]}"
		iuse=ldc2-$(ver_rs 1- _ $dc_version)
		if [ "${DLANG_PACKAGE_TYPE}" == "multi" ]; then
			depend="[${MULTILIB_USEDEP}]"
		else
			depend=""
		fi
		depend="dev-lang/ldc2:$dc_version=$depend"
		_dlang_compiler_masked_archs_for_version_range "$iuse" "$depend" "$mapping" "$1" "$2"
	done
}

# @FUNCTION: _dlang_filter_versions
# @DESCRIPTION:
# This function sets up the preliminary REQUIRED_USE, DEPEND and RDEPEND ebuild
# variables with compiler requirements for the current ebuild.
# If DLANG_VERSION_RANGE is set in the ebuild, this variable will be parsed to
# limit the search on the known compatible Dlang front-end versions.
# DLANG_PACKAGE_TYPE determines whether the current ebuild can be compiled for
# multiple Dlang compilers (i.e. is a library to be installed for different
# versions of dmd, gdc or ldc2) or a single compiler (i.e. is an application).
_dlang_filter_versions() {
	local range start stop matches d_version versions do_start
	local -A valid

	# Use given range to create a positive list of supported D versions
	if [[ -v DLANG_VERSION_RANGE ]]; then
		for range in $DLANG_VERSION_RANGE; do
			# Define start and stop of range
			if [[ "${range}" == *?- ]]; then
				start="${range%-}"
				stop=
			elif [[ "${range}" == -?* ]]; then
				start=
				stop="${range#-}"
			elif [[ "${range}" == *?-?* ]]; then
				start="${range%-*}"
				stop="${range#*-}"
			else
				start="${range}"
				stop="${range}"
			fi
			_dlang_filter_compilers "$start" "$stop"
		done
	else
		_dlang_filter_compilers "" ""
	fi

	[ ${#_dlang_compiler_iuse[@]} -eq 0 ] && die "No Dlang compilers found that satisfy this package's version range: $DLANG_VERSION_RANGE"

	if [ "${DLANG_PACKAGE_TYPE}" != "multi" ]; then
		REQUIRED_USE="^^"
	else
		REQUIRED_USE="||"
	fi
	DEPEND="${_dlang_depends[@]}"
	# DMD, is statically linked and does not have its host compiler as a runtime dependency.
	if [ "${DLANG_PACKAGE_TYPE}" == "dmd" ]; then
		IUSE="${_dlang_compiler_iuse[@]} +selfhost"
		_dlang_compiler_iuse+=( selfhost )
	else
		RDEPEND="$DEPEND"
		IUSE="${_dlang_compiler_iuse[@]}"
	fi
	REQUIRED_USE="${REQUIRED_USE} ( ${_dlang_compiler_iuse[@]} ) ${_dlang_compiler_iuse_mask[@]}"

	local -a compiler
	for compiler in ${_dlang_compiler_iuse[@]}; do
		DLANG_COMPILER_USE="${DLANG_COMPILER_USE}${compiler}?,"
	done
	DLANG_COMPILER_USE="${DLANG_COMPILER_USE:0:-1}"
}

# @FUNCTION: _dlang_phase_wrapper
# @DESCRIPTION:
# A more or less typical ebuild phase wrapper that invokes `d_src_*` phases if defined in an ebuild or calls Portage's
# default implementation otherwise. when multiple build configurations are provided it also takes care of invoking
# phases once for each configuration as well as calling `d_src_*_all` if defined after the phase has been run for each
# individual build configuration.
_dlang_phase_wrapper() {
	dlang_phase() {
		if declare -f d_src_${1} >/dev/null ; then
			d_src_${1}
		else
			default_src_${1}
		fi
	}

	if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]]; then
		dlang_foreach_config dlang_phase "${1}"
		# Handle any compiler & arch independent installation steps
		if declare -f d_src_${1}_all >/dev/null ; then
			d_src_${1}_all
		fi
	else
		dlang_single_config dlang_phase "${1}"
	fi
}

# @FUNCTION: _dlang_compiler_to_dlang_version
# @DESCRIPTION:
# Given two arguments, a compiler vendor and a compiler version, this function retrieves the corresponding supported
# Dlang front-end (language) version. This is used in filtering compilers offering incompatible language versions for
# some packages. The resulting language version is echo'd.
_dlang_compiler_to_dlang_version() {
	local mapping
	case "$1" in
		"dmd")
			mapping="$2"
		;;
		"gdc")
			mapping=`echo ${_dlang_gdc_frontend[$2]} | cut -f 1 -d " "`
		;;
		"ldc2")
			mapping=`echo ${_dlang_ldc2_frontend[$2]} | cut -f 1 -d " "`
		;;
	esac
	[ -n "${mapping}" ] || die "Could not retrieve dlang version for '$1-$2'."
	echo "${mapping}"
}

# @FUNCTION: _dlang_build_configurations
# @DESCRIPTION:
# Creates a list of all the build configurations we are going to compile. As all Dlang compilers have different ABIs,
# potentially changing from one release to the next, I decided to distinguish the compiler vendor, compiler version and
# architecture. An application typically only uses on build configuration, but libraries like GtkD may be installed for
# many compiler versions as well as in 32-bit and 64-bit at the same time on multilib. The result is echo'd.
_dlang_build_configurations() {
	local variants version_component use_flag use_flags

	if [ -z ${DLANG_USE_COMPILER+x} ]; then
		use_flags="${USE}"
	else
		use_flags="${DLANG_USE_COMPILER}"
	fi
	for use_flag in $use_flags; do
		case ${use_flag} in
			dmd-* | gdc-* | ldc-* | ldc2-*)
				# On the left are possible $use_flag,
				# on the right, the correct $version_component:
				#
				# dmd-2_088              dmd-2.088
				# gdc-12                 gdc-12
				# gdc-11                 gdc-11
				# ldc-1_29               ldc-1.29
				# ldc2-1_30              ldc2-1.30
				#
				# Note: for ldc2 there is an empty separater betwen the 'c' and the '2'.
				if [[ "${use_flag}" =~ ldc2-* ]]; then
					version_component=$(ver_rs 3 . ${use_flag})
				else
					version_component=$(ver_rs 2-3 . ${use_flag})
				fi

				if [ "${DLANG_PACKAGE_TYPE}" == "multi" ]; then
					for abi in $(multilib_get_enabled_abis); do
						variants="${variants} ${abi}-${version_component}"
					done
				else
					variants="default-${version_component}"
				fi
				;;
			selfhost)
				if [ "${DLANG_PACKAGE_TYPE}" == "dmd" ]; then
					variants="default-dmd-selfhost"
				fi
				;;
		esac
	done
	if [ -z "${variants}" ]; then
		die "At least one compiler USE-flag must be selected. This should be checked by REQUIRED_USE in this package."
	fi
	echo ${variants}
}

# @FUNCTION: _dlang_use_build_vars
# @DESCRIPTION:
# Sets and exports important environment variables pertaining to the current build configuration.
# LDFLAGS are also converted into their compiler specific equivalents here.
_dlang_use_build_vars() {
	# Now we define some variables and then call the function.
	# LIBDIR_${ABI} is used by the dolib.* functions, that's why we override it per compiler.
	# The original value is exported as LIBDIR_HOST.
	local libdir_var="LIBDIR_${ABI}"
	export LIBDIR_HOST="${!libdir_var}"
	export ABI="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f1)"
	export DC="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f2)"
	export DC_VERSION="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f3)"
	case "${DC:0:3}" in
		"dmd") export DLANG_VENDOR="DigitalMars" ;;
		"gdc") export DLANG_VENDOR="GNU" ;;
		"ldc") export DLANG_VENDOR="LDC" ;;
	esac
	export DLANG_VERSION="$(_dlang_compiler_to_dlang_version ${DC} ${DC_VERSION})"
	case "${ABI}" in
		"default") ;;
		"x86"*)    export MODEL=32 ;;
		*)         export MODEL=64 ;;
	esac
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		if [ "${DC_VERSION}" != "selfhost" ]; then
			export DC="/usr/lib/dmd/${DC_VERSION}/bin/dmd"
			export DMD="${DC}"
		fi
		# "lib" on pure x86, "lib{32,64}" on amd64 (and multilib)
		if has_multilib_profile || [[ "${MODEL}" == "64" ]]; then
			export LIBDIR_${ABI}="../usr/lib/dmd/${DC_VERSION}/lib${MODEL}"
		else
			export LIBDIR_${ABI}="../usr/lib/dmd/${DC_VERSION}/lib"
		fi
		export DCFLAGS="${DMDFLAGS}"
		export DLANG_LINKER_FLAG="-L"
		export DLANG_A_FLAGS="-lib -fPIC"
		export DLANG_SO_FLAGS="-shared -defaultlib=libphobos2.so -fPIC"
		export DLANG_OUTPUT_FLAG="-of"
		export DLANG_VERSION_FLAG="-version"
		export DLANG_UNITTEST_FLAG="-unittest"
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		# Note that ldc2 expects the compiler name to be 'gdmd', not 'x86_64-pc-linux-gnu-gdmd'.
		# gcc's SLOT is its major version component.
		export DC="/usr/${CHOST_default}/gcc-bin/${DC_VERSION}/${CHOST_default}-gdc"
		export DMD="/usr/${CHOST_default}/gcc-bin/${DC_VERSION}/gdmd"
		if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]] && multilib_is_native_abi; then
			export LIBDIR_${ABI}="lib/gcc/${CHOST_default}/${DC_VERSION}"
		else
			export LIBDIR_${ABI}="lib/gcc/${CHOST_default}/${DC_VERSION}/${MODEL}"
		fi
		export DCFLAGS="${GDCFLAGS} -shared-libphobos"
		export DLANG_LINKER_FLAG="-Xlinker "
		export DLANG_SO_FLAGS="-shared -fpic"
		export DLANG_OUTPUT_FLAG="-o "
		export DLANG_VERSION_FLAG="-fversion"
		export DLANG_UNITTEST_FLAG="-funittest"
	elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		export LIBDIR_${ABI}="../usr/lib/ldc2/${DC_VERSION}/lib${MODEL}"
		export DMD="/usr/lib/ldc2/${DC_VERSION}/bin/ldmd2"
		export DC="/usr/lib/ldc2/${DC_VERSION}/bin/ldc2"
		# To allow separate compilation and avoid object file name collisions,
		# we append -op (do not strip paths from source file).
		export DCFLAGS="${LDCFLAGS} -op"
		export DLANG_LINKER_FLAG="-L="
		export DLANG_A_FLAGS="-lib -relocation-model=pic"
		export DLANG_SO_FLAGS="-shared -relocation-model=pic"
		export DLANG_OUTPUT_FLAG="-of="
		export DLANG_VERSION_FLAG="-d-version"
		export DLANG_UNITTEST_FLAG="-unittest"
	else
		die "Could not detect D compiler vendor!"
	fi
	# We need to convert the LDFLAGS, so they are understood by DMD and LDC.
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		# gc-sections breaks executables for some versions of D
		# It works with the gold linker on the other hand
		# See: https://issues.dlang.org/show_bug.cgi?id=879
		[[ "${DLANG_PACKAGE_TYPE}" == "dmd" ]] && local dlang_version=$SLOT || local dlang_version=$DLANG_VERSION
		if ver_test $dlang_version -lt 2.072; then
			if ! ld -v | grep -q "^GNU gold"; then
				filter-flags {-L,-Xlinker,-Wl\,}--gc-sections
			fi
		fi
		# Filter ld.gold ICF flag. (https://issues.dlang.org/show_bug.cgi?id=17515)
		filter-flags {-L,-Xlinker,-Wl\,}--icf={none,all,safe}
	fi

	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]] || [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		# DMD and GDC don't undestand/work with LTO flags
		filter-ldflags -f{no-,}use-linker-plugin -f{no-,}lto -flto=*
	fi
	export LDFLAGS=`dlang_convert_ldflags`
	"${@}"
}

# @FUNCTION: _dlang_prefix_words
# @DESCRIPTION:
# A simple helper function that prefixes the first argument to all other arguments and echo's the resulting line.
_dlang_prefix_words() {
	for arg in ${*:2}; do
		echo -n " $1$arg"
	done
}

# @FUNCTION: _dlang_additional_flags
# @DESCRIPTION:
# This function is internally used by the dlang_compile_bin/lib/so functions. When `debug` is among the enabled IUSE
# flags, this function ensures that a debug build of the Dlang package is produced. It also provides the additional
# flags for any imports and libraries mentioned in an ebuild in the compiler specific syntax. The resulting flags are
# echo'd.
_dlang_additional_flags() {
	# For info on debug use flags see:
	# https://wiki.gentoo.org/wiki/Project:Quality_Assurance/Backtraces#debug_USE_flag
	case "${DLANG_VENDOR}" in
		"DigitalMars")
			local import_prefix="-I"
			local string_import_prefix="-J"
			local debug_flags="-debug"
			;;
		"GNU")
			local import_prefix="-I"
			local string_import_prefix="-J"
			local debug_flags="-fdebug"
			;;
		"LDC")
			local import_prefix="-I="
			local string_import_prefix="-J="
			local debug_flags="-d-debug"
			;;
	esac
	echo $(has debug ${IUSE} && use debug && echo ${debug_flags})\
		$(_dlang_prefix_words "${DLANG_VERSION_FLAG}=" $versions)\
		$(_dlang_prefix_words $import_prefix $imports)\
		$(_dlang_prefix_words $string_import_prefix $string_imports)\
		$(_dlang_prefix_words "${DLANG_LINKER_FLAG}-l" $libs)
}

# Setting DLANG_USE_COMPILER skips the generation of USE-flags for compilers
if [ -z ${DLANG_USE_COMPILER+x} ]; then
	set -f; _dlang_filter_versions; set +f
fi

fi
