# @ECLASS: dlang.eclass
# @MAINTAINER: marco.leise@gmx.de
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
# For a single compiler use "single", for multiple compilers use "multi".
# DLANG_USE_COMPILER, if set, inhibits the generation of IUSE, REQUIRED_USE, DEPEND
# and RDEPEND for Dlang compilers based on above variables. The ebuild is responsible
# for providing them as required by the function it uses from this eclass.

if [[ ${___ECLASS_ONCE_DLANG} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_DLANG="recur -_+^+_- spank"

if has ${EAPI:-0} 0 1 2 3 4 5; then
	die "EAPI must be >= 6 for dlang packages."
fi

inherit flag-o-matic versionator dlang-compilers
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
# DC: D compiler command. E.g. /opt/dmd-2.067/bin/dmd, /opt/ldc2-0.12.0/bin/ldc2
#   or /usr/x86_64-pc-linux-gnu/gcc-bin/4.8.1/x86_64-pc-linux-gnu-gdc
# DMD: DMD compiler command. E.g. /opt/dmd-2.069/bin/dmd,
#   /opt/ldc2-0.16/bin/ldmd2 or
#   /usr/x86_64-pc-linux-gnu/gcc-bin/4.8.4/x86_64-pc-linux-gnu-gdmd
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
# DLANG_IMPORT_DIR: This is actually set globally. Place includes in a
#   sub-directory.
dlang_foreach_config() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=($(__dlang_build_configurations))

	multibuild_wrapper() {
		debug-print-function ${FUNCNAME} "${@}"

		# We need to reset CC, else when dmd calls it, the result is:
		# "x86_64-pc-linux-gnu-gcc -m32": No such file or directory
		if [[ -v CC ]]; then
			local __ORIGINAL_CC="${CC}"
		fi
		multilib_toolchain_setup "${ABI}"
		if [[ -v __ORIGINAL_CC ]]; then
			CC="${__ORIGINAL_CC}"
		else
			unset CC
		fi
		mkdir -p "${BUILD_DIR}" || die
		pushd "${BUILD_DIR}" >/dev/null || die
		__dlang_use_build_vars "${@}"
		popd >/dev/null || die
	}

	multibuild_foreach_variant multibuild_wrapper "${@}"
}

export DLANG_IMPORT_DIR="usr/include/dlang"

dlang_single_config() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANT=$(__dlang_build_configurations)

	__dlang_use_build_vars "${@}"
}

dlang_has_shared_lib_support() {
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		[[ $(get_major_version ${DLANG_VERSION}) -eq 2 ]] && [[ $((10#$(get_after_major_version ${DLANG_VERSION}))) -ge 63 ]]
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		[[ $(get_major_version ${DLANG_VERSION}) -eq 2 ]] && [[ $((10#$(get_after_major_version ${DLANG_VERSION}))) -ge 68 ]]
	elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		return 1
	else
		die "Could not detect D compiler vendor!"
	fi
}


# @FUNCTION: dlang_src_prepare
# @DESCRIPTION:
# Create a single copy of the package sources for each enabled D configuration.
dlang_src_prepare() {
	debug-print-function ${FUNCNAME} "${@}"

	default_src_prepare

	if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]]; then
		local MULTIBUILD_VARIANTS=($(__dlang_build_configurations))
		multibuild_copy_sources
	fi
}

dlang_src_configure() {
	__dlang_phase_wrapper configure
}

dlang_src_compile() {
	__dlang_phase_wrapper compile
}

dlang_src_test() {
	__dlang_phase_wrapper test
}

dlang_src_install() {
	__dlang_phase_wrapper install
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
#
# Aditionally, if the ebuild offers the "debug" use flag, we will automatically
# raise the debug level to 1 during compilation.
dlang_compile_bin() {
	[[ "${DLANG_PACKAGE_TYPE}" == "single" ]] || die "Currently ${FUNCTION} only works with DLANG_PACKAGE_TYPE=\"single\"."

	local binname="${1}"
	local sources="${@:2}"

	dlang_exec ${DC} ${DCFLAGS} ${sources} $(__dlang_additional_flags) \
		${LDFLAGS} ${DLANG_OUTPUT_FLAG}${binname}
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

	dlang_exec ${DC} ${DCFLAGS} -m${MODEL} ${sources} $(__dlang_additional_flags) \
		${LDFLAGS} ${DLANG_SO_FLAGS} ${DLANG_LINKER_FLAG}-soname=${soname} \
		${DLANG_OUTPUT_FLAG}${libname}
}

# @FUNCTION: dlang_convert_ldflags
# @DESCRIPTION:
# Makes linker flags meant for GCC understandable for the current D compiler.
# Basically it replaces -L with what the D compiler uses as linker prefix.
dlang_convert_ldflags() {
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		# gc-sections breaks executables for some versions of D
		# It works with the gold linker on the other hand
		# See: https://issues.dlang.org/show_bug.cgi?id=879
		if ! version_is_at_least 2.072 $DLANG_VERSION; then
			if ! ld -v | grep -q "^GNU gold"; then
				filter-ldflags {-L,-Xlinker,-Wl,}--gc-sections
			fi
		fi
	fi

	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]] || [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		# DMD and GDC don't undestand/work with LTO flags
		filter-ldflags -f{no-,}use-linker-plugin -f{no-,}lto -flto=*
	fi

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

# @FUNCTION: dlang_system_imports
# @DESCRIPTION:
# Returns a list of standard system import paths (one per line) for the current
# D compiler. This includes druntime and Phobos as well as compiler specific
# paths.
dlang_system_imports() {
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		echo "/opt/dmd-${DC_VERSION}/import"
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		echo "/usr/lib/gcc/${CHOST_default}/${DC_VERSION}/include/d"
	elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		echo "/opt/ldc2-${DC_VERSION}/include/d"
		echo "/opt/ldc2-${DC_VERSION}/include/d/ldc"
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
		[ "$DLANG_PACKAGE_TYPE" == "single" ] || die "'dlang_phobos_level' needs 'DLANG_PACKAGE_TYPE == single' when called outside of compiles."
		local config=`__dlang_build_configurations`
		local dc="$(echo ${config} | cut -d- -f2)"
		local dc_version="$(echo ${config} | cut -d- -f3)"
		local DLANG_VERSION="$(__dlang_compiler_to_dlang_version ${dc} ${dc_version})"
	fi
	version_is_at_least "$1" "$DLANG_VERSION"
}

### Non-public helper functions ###

declare -a __dlang_compiler_iuse
declare -a __dlang_compiler_iuse_mask
declare -a __dlang_depends

__dlang_compiler_masked_archs_for_version_range() {
	# Given a Dlang compiler represented through an IUSE flag (e.g. "ldc2-1_1")
	# and DEPEND atom (e.g. "dev-lang/ldc2:1.1="), this function tests if the
	# current ebuild can depend and thus be compiled with that compiler on
	# one or more architectures.
	# A compiler that is less stable than the current ebuild for all
	# architectures, is dropped completely. A compiler that disqualifies
	# for only some, but not all architectures, on the other hand, is disabled
	# though REQUIRED_USE (e.g. "!amd64? ( ldc2-1_1? ( dev-lang/ldc2:1.1= ) )").
	# Available compilers are accumulated in the __dlang_compiler_iuse array,
	# which is later turned into the IUSE variable.
	# Partially available compilers are additionally masked out for particular
	# architectures by adding them to the __dlang_compiler_iuse_mask array,
	# which is later appended to REQUIRED_USE.
	# Finally, the __dlang_depends array receives the USE-flag enabled
	# dependencies on Dlang compilers, which is later turned into DEPEND and
	# RDEPEND.

	local iuse=$1
	local depend="$iuse? ( $2 )"
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

	# If we run portage, check if our list of known architectures is
	# still up to date.
	if [ -n "$USE_EXPAND_VALUES_ARCH" ]; then
		if [ "$USE_EXPAND_VALUES_ARCH" != "$__dlang_archs" ]; then
			ewarn "Dlang overlay maintenance: __dlang_archs diverged from Portage's USE_EXPAND_VALUES_ARCH"
		fi
	fi

	# Check the stability requirements
	local ebuild_stab comp_stab have_one=0
	for arch in $__dlang_archs; do
		ebuild_stab=0
		for package_keyword in $KEYWORDS; do
			if [ "$package_keyword" == "~$arch" ]; then
				ebuild_stab=1
			elif [ "$package_keyword" == "$arch" ]; then
				ebuild_stab=2
			fi
		done
		if [ $ebuild_stab -gt 0 ]; then
			comp_stab=0
			for compiler_keyword in $compiler_keywords; do
				if [ "$compiler_keyword" == "~$arch" ]; then
					comp_stab=1
				elif [ "$compiler_keyword" == "$arch" ]; then
					comp_stab=2
				fi
			done
			if [ $comp_stab -lt $ebuild_stab ]; then
				masked_archs+=( $arch )
			else
				have_one=1
			fi
		fi
	done
	[ $have_one -eq 0 ] && return 1

	__dlang_compiler_iuse+=( $iuse )
	if [ "${#masked_archs[@]}" -ne 0 ]; then
		for arch in ${masked_archs[@]}; do
			__dlang_compiler_iuse_mask+=( "${arch}? ( !${iuse} )" )
			depend="!${arch}? ( ${depend} )"
		done
	fi
	__dlang_depends+=( "$depend" )
}

__dlang_filter_compilers() {
	# Given a range of Dlang front-end version that the current ebuild can be built with,
	# this function goes through each compatible Dlang compilers as provided by the file
	# dlang-compilers.eclass and then calls __dlang_compiler_masked_archs_for_version_range
	# where they will be further scrutinized for architecture stability requirements and
	# then either dropped as option or partially masked.

	local dc_version mapping iuse depend

	# filter for DMD (hardcoding support for x86 and amd64 only)
	for dc_version in "${!__dlang_dmd_frontend[@]}"; do
		mapping="${__dlang_dmd_frontend[${dc_version}]}"
		iuse="dmd-$(replace_all_version_separators _ $dc_version)"
		if [ "${DLANG_PACKAGE_TYPE}" == "multi" ]; then
			depend="[${MULTILIB_USEDEP}]"
		else
			depend=""
		fi
		depend="dev-lang/dmd:$dc_version=$depend"
		__dlang_compiler_masked_archs_for_version_range "$iuse" "$depend" "$mapping" "$1" "$2"
	done

	# GDC (doesn't support sub-slots, to stay compatible with upstream GCC)
	for dc_version in "${!__dlang_gdc_frontend[@]}"; do
		mapping="${__dlang_gdc_frontend[${dc_version}]}"
		iuse=gdc-$(replace_all_version_separators _ $dc_version)
		depend="=sys-devel/gcc-${dc_version}*[d]"
		__dlang_compiler_masked_archs_for_version_range "$iuse" "$depend" "$mapping" "$1" "$2"
	done

	# filter for LDC2
	for dc_version in "${!__dlang_ldc2_frontend[@]}"; do
		mapping="${__dlang_ldc2_frontend[${dc_version}]}"
		iuse=ldc2-$(replace_all_version_separators _ $dc_version)
		depend="dev-lang/ldc2:${dc_version}="
		__dlang_compiler_masked_archs_for_version_range "$iuse" "$depend" "$mapping" "$1" "$2"
	done
}

__dlang_filter_versions() {
	# This function sets up the preliminary REQUIRED_USE, DEPEND and RDEPEND ebuild
	# variables with compiler requirements for the current ebuild.
	# If DLANG_VERSION_RANGE is set in the ebuild, this variable will be parsed to
	# limit the search on the known compatible Dlang front-end versions.
	# DLANG_PACKAGE_TYPE determines whether the current ebuild can be compiled for
	# multiple Dlang compilers (i.e. is a library to be installed for different
	# versions of dmd, gdc or ldc2) or a single compiler (i.e. is an application).

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
				start="$(echo "${range}" | cut -d- -f1)"
				stop="$(echo "${range}" | cut -d- -f2)"
			else
				start="${range}"
				stop="${range}"
			fi
			__dlang_filter_compilers "$start" "$stop"
		done
	else
		__dlang_filter_compilers "" ""
	fi

	[ ${#__dlang_compiler_iuse[@]} -eq 0 ] && die "No Dlang compilers found that satisfy this package's version range: $DLANG_VERSION_RANGE"

	IUSE="${__dlang_compiler_iuse[@]}"
	if [ "${DLANG_PACKAGE_TYPE}" == "single" ]; then
		REQUIRED_USE="^^"
	else
		REQUIRED_USE="||"
	fi
	REQUIRED_USE="${REQUIRED_USE} ( ${__dlang_compiler_iuse[@]} ) ${__dlang_compiler_iuse_mask[@]}"
	DEPEND="${__dlang_depends[@]}"
	RDEPEND="$DEPEND"
}

__dlang_phase_wrapper() {
	dlang_phase() {
		if declare -f d_src_${1} >/dev/null ; then
			d_src_${1}
		else
			default_src_${1}
		fi
	}

	if [[ "${DLANG_PACKAGE_TYPE}" == "single" ]]; then
		dlang_single_config dlang_phase "${1}"
	else
		dlang_foreach_config dlang_phase "${1}"
		# Handle any compiler & arch independent installation steps
		if declare -f d_src_${1}_all >/dev/null ; then
			d_src_${1}_all
		fi
	fi
}

__dlang_compiler_to_dlang_version() {
	local mapping
	case "$1" in
		"dmd")
			mapping="$2"
		;;
		"gdc")
			mapping=`echo ${__dlang_gdc_frontend[$2]} | cut -f 1 -d " "`
		;;
		"ldc2")
			mapping=`echo ${__dlang_ldc2_frontend[$2]} | cut -f 1 -d " "`
		;;
	esac
	[ -n "${mapping}" ] || die "Could not retrieve dlang version for '$1-$2'."
	echo "${mapping}"
}

__dlang_build_configurations() {
	local variants use_flag use_flags

	if [ -z ${DLANG_USE_COMPILER+x} ]; then
		use_flags="${USE}"
	else
		use_flags="${DLANG_USE_COMPILER}"
	fi
	for use_flag in $use_flags; do
		case ${use_flag} in
			dmd-* | gdc-* | ldc-* | ldc2-*)
				if [[ "${DLANG_PACKAGE_TYPE}" == "single" ]]; then
					variants="default-${use_flag//_/.}"
				else
					for abi in $(multilib_get_enabled_abis); do
						variants="${variants} ${abi}-${use_flag//_/.}"
					done
				fi
				;;
		esac
	done
	if [[ -z ${variants} ]]; then
		die "At least one compiler USE-flag must be selected. This should be checked by REQUIRED_USE in this package."
	fi
	echo ${variants}
}

__dlang_use_build_vars() {
	# Now we define some variables and then call the function.
	export ABI="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f1)"
	export DC="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f2)"
	export DC_VERSION="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f3)"
	case "${DC:0:3}" in
		"dmd") export DLANG_VENDOR="DigitalMars" ;;
		"gdc") export DLANG_VENDOR="GNU" ;;
		"ldc") export DLANG_VENDOR="LDC" ;;
	esac
	export DLANG_VERSION="$(__dlang_compiler_to_dlang_version ${DC} ${DC_VERSION})"
	case "${ABI}" in
		"default") ;;
		"x86"*)    export MODEL=32 ;;
		*)         export MODEL=64 ;;
	esac
	if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
		export DC="/opt/${DC}-${DC_VERSION}/bin/dmd"
		export DMD="${DC}"
		# "lib" on pure x86, "lib{32,64}" on amd64 (and multilib)
		if has_multilib_profile || [[ "${MODEL}" == "64" ]]; then
			export LIBDIR_${ABI}="../opt/dmd-${DC_VERSION}/lib${MODEL}"
		else
			export LIBDIR_${ABI}="../opt/dmd-${DC_VERSION}/lib"
		fi
		export DCFLAGS="${DMDFLAGS}"
		export DLANG_LINKER_FLAG="-L"
		export DLANG_SO_FLAGS="-shared -defaultlib=libphobos2.so -fPIC"
		export DLANG_OUTPUT_FLAG="-of"
		export DLANG_VERSION_FLAG="-version"
	elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
		export DC="/usr/${CHOST_default}/gcc-bin/${DC_VERSION}/${CHOST_default}-gdc"
		export DMD="/usr/${CHOST_default}/gcc-bin/${DC_VERSION}/${CHOST_default}-gdmd"
		if [[ "${DLANG_PACKAGE_TYPE}" == "multi" ]] && multilib_is_native_abi; then
			export LIBDIR_${ABI}="lib/gcc/${CHOST_default}/${DC_VERSION}"
		else
			export LIBDIR_${ABI}="lib/gcc/${CHOST_default}/${DC_VERSION}/${MODEL}"
		fi
		export DCFLAGS="${GDCFLAGS}"
		if dlang_has_shared_lib_support; then
			export DCFLAGS="${DCFLAGS} -shared-libphobos"
		fi
		export DLANG_LINKER_FLAG="-Xlinker "
		export DLANG_SO_FLAGS="-shared -fPIC"
		export DLANG_OUTPUT_FLAG="-o "
		export DLANG_VERSION_FLAG="-fversion"
	elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
		export LIBDIR_${ABI}="../opt/${DC}-${DC_VERSION}/lib${MODEL}"
		export DMD="/opt/${DC}-${DC_VERSION}/bin/ldmd2"
		export DC="/opt/${DC}-${DC_VERSION}/bin/ldc2"
		# To allow separate compilation and avoid object file name collisions,
		# we append -op (do not strip paths from source file).
		export DCFLAGS="${LDCFLAGS} -op"
		export DLANG_LINKER_FLAG="-L="
		export DLANG_SO_FLAGS="-shared -relocation-model=pic"
		export DLANG_OUTPUT_FLAG="-of="
		export DLANG_VERSION_FLAG="-d-version"
	else
		die "Could not detect D compiler vendor!"
	fi
	# We need to convert the LDFLAGS, so they are understood by DMD and LDC.
	export LDFLAGS=`dlang_convert_ldflags`
	"${@}"
}

__dlang_prefix_words() {
	for arg in ${*:2}; do
		echo -n " $1$arg"
	done
}

__dlang_additional_flags() {
	# For info on debug use flags see:
	# https://wiki.gentoo.org/wiki/Project:Quality_Assurance/Backtraces#debug_USE_flag
	case "${DLANG_VENDOR}" in
		"DigitalMars")
			local version_prefix="-version="
			local import_prefix="-I"
			local string_import_prefix="-J"
			local debug_flags="-debug"
			;;
		"GNU")
			local version_prefix="-fversion="
			local import_prefix="-I"
			local string_import_prefix="-J"
			local debug_flags="-fdebug"
			;;
		"LDC")
			local version_prefix="-d-version="
			local import_prefix="-I="
			local string_import_prefix="-J="
			local debug_flags="-d-debug"
			;;
	esac
	echo $(has debug ${IUSE} && use debug && echo ${debug_flags})\
		$(__dlang_prefix_words $version_prefix $versions)\
		$(__dlang_prefix_words $import_prefix $imports)\
		$(__dlang_prefix_words $string_import_prefix $string_imports)\
		$(__dlang_prefix_words "${DLANG_LINKER_FLAG}-l" $libs)
}

# Setting DLANG_USE_COMPILER skips the generation of USE-flags for compilers
if [ -z ${DLANG_USE_COMPILER+x} ]; then
	set -f; __dlang_filter_versions; set +f
fi

fi
