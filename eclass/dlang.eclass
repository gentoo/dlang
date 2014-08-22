# @ECLASS: dlang.eclass
# @MAINTAINER: marco.leise@gmx.de
# @BLURB:
# install D libraries in multiple locations for each  D version and compiler
# @DESCRIPTION:
# The dlang eclass faciliates creating dependiencies on D libraries for use
# with different D compilers and D versions.

if [[ ${___ECLASS_ONCE_DLANG} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_DLANG="recur -_+^+_- spank"

if has ${EAPI:-0} 0 1 2 3; then
	die "EAPI must be >= 4 for dlang packages."
fi

inherit versionator
if [[ "${DLANG_PACKAGE_TYPE}" != "single" ]]; then
	# We handle a multi instance package.
	inherit multilib-minimal
fi

EXPORT_FUNCTIONS src_configure src_compile src_test src_install

export DLANG_IMPORT_DIR="/usr/include/dlang"

dlang_convert_ldflags() {
	if [[ "${DLANG_VENDOR}" == "dmd" ]] || [[ "${DLANG_VENDOR}" == "ldc" ]]; then
		local set repl flags=()
		if [[ is_dmd ]]; then
			repl="-L"
		elif [[ is_ldc ]]; then
			repl="-L="
		fi
		for set in ${LDFLAGS}; do
			if [[ "${set:0:4}" == "-Wl," ]]; then
				set=${set/-Wl,/${repl}}
				flags+=(${set//,/ ${repl}})
			elif [[ "${set:0:8}" == "-Xlinker" ]]; then
				flags+=(${set/-Xlinker/${repl}})
			elif [[ "${set:0:2}" == "-L" ]]; then
				flags+=(${set/-L/${repl}-L})
			else
				flags+=(${set})
			fi
		done
		echo "${flags[@]}"
	elif [[ "${DLANG_VENDOR}" == "gdc" ]]; then
		echo "${LDFLAGS}"
	else
		die "Set DLANG_VENDOR to dmd, ldc or gdc prior to calling ${FUNCNAME}()."
	fi
}

__dlang_use_build_vars() {
	# Now we define some variables and then call the function.
	export ABI="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f1)"
	export DC="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f2)"
	export DC_VERSION="$(echo ${MULTIBUILD_VARIANT} | cut -d- -f3)"
	export DLANG_VENDOR="${DC:0:3}"
	export DLANG_VERSION="$(__dlang_compiler_to_dlang_version ${DC} ${DC_VERSION})"
	case "${ABI}" in
		"default") ;;
		"x86"*)    export MODEL=32 ;;
		*)         export MODEL=64 ;;
	esac
	if [[ "${DLANG_VENDOR}" == "dmd" ]]; then
		export DC="/opt/${DC}-${DC_VERSION}/bin/dmd"
		export DMD="${DC}"
		export DLANG_LIB_DIR="/opt/dmd-${DC_VERSION}/$(get_libdir)"
		export DCFLAGS="${DMDFLAGS}"
	elif [[ "${DLANG_VENDOR}" == "gdc" ]]; then
		export DC="/usr/${__DLANG_CHOST}/gcc-bin/${DC_VERSION}/gdc"
		export DMD="/usr/${__DLANG_CHOST}/gcc-bin/${DC_VERSION}/gdmd"
		if [[ "${MODEL}" == "32" ]]; then
			export DLANG_LIB_DIR="/usr/lib/gcc/${__DLANG_CHOST}/${DC_VERSION}/32"
		else
			export DLANG_LIB_DIR="/usr/lib/gcc/${__DLANG_CHOST}/${DC_VERSION}"
		fi
		export DCFLAGS="${GDCFLAGS}"
	elif [[ "${DLANG_VENDOR}" == "ldc" ]]; then
		export DLANG_LIB_DIR="/opt/${DC}-${DC_VERSION}/$(get_libdir)"
		export DMD="/opt/${DC}-${DC_VERSION}/bin/ldmd2"
		export DC="/opt/${DC}-${DC_VERSION}/bin/ldc2"
		export DCFLAGS="${LDCFLAGS}"
	else
		die "Could not detect D compiler vendor!"
	fi
	# We need to convert the LDFLAGS, so they are understood by DMD and LDC.
	export LDFLAGS="$(dlang_convert_ldflags)"
	"${@}"
}


# @FUNCTION: dlang_foreach_config
# @DESCRIPTION:
# Function that calls its arguments for each D configuration. A few environment
# variables will be set for each call:
# ABI: See 'multilib_get_enabled_abis' from multilib-build.eclass.
# MODEL: This is either 32 or 64.
# DC: D compiler command. E.g. dmd2.064, ldc2-0.12.0 or
#   /usr/x86_64-pc-linux-gnu/gcc-bin/4.8.1/x86_64-pc-linux-gnu-gdc
# DLANG_VENDOR: Either dmd, gdc or ldc.
# DC_VERSION: Release version of the compiler. This is the version excluding any
#   Patch releases. So dmd 2.064.2 would still be 2.064. This version is used
#   to separate potentially incompatible ABIs and to create the library path.
#   Typical versions of gdc or ldc are 4.8.1 or 0.12.
# DLANG_VERSION: This differs from DC_VERSION in so far as it displays the
#   front-end or language specification version for every compiler. Since the
#   release of D1 it follows the scheme x.yyy and is as of writing at 2.064.
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

dlang_single_config() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANT=$(__dlang_build_configurations)

	__dlang_use_build_vars "${@}"
}

# @FUNCTION: dlang_copy_sources
# @DESCRIPTION:
# Create a single copy of the package sources for each enabled D configuration.
dlang_copy_sources() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=($(__dlang_build_configurations))
	multibuild_copy_sources
}

dlang_has_shared_lib_support() {
	if [[ "${DLANG_VENDOR}" == "dmd" ]]; then
		[[ "$(get_major_version ${DLANG_VERSION})" -eq 2 ]] && [[ "$(get_after_major_version ${DLANG_VERSION})" -ge 063 ]]
	elif [[ "${DLANG_VENDOR}" == "gdc" ]]; then
		return 1
	elif [[ "${DLANG_VENDOR}" == "ldc" ]]; then
		return 1
	else
		die "Could not detect D compiler vendor!"
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

### Non-public helper functions ###

# Generate arrays of all D versions
__DLANG_VERSIONS_1=()
__DLANG_VERSIONS_2=()
for v0 in {43..46} {48..59} 61 {63..82} 86 {88..178}; do
	__DLANG_VERSIONS_1+=("0.${v0}")
done
for v1 in 00 {001..007} {009..076}; do
	__DLANG_VERSIONS_1+=("1.${v1}")
done
for v2 in {000..023} {025..065}; do
	__DLANG_VERSIONS_2+=("2.${v2}")
done
__DLANG_VERSIONS=("${__DLANG_VERSIONS_1[@]}" "${__DLANG_VERSIONS_2[@]}")

__dlang_filter_versions() {
	# Use given range to create a positive list of supported D versions
	local ranges start stop d_version matches versions do_start
	local -A valid
	if [[ -v DLANG_VERSION_RANGE ]]; then
		ranges=(${DLANG_VERSION_RANGE})
		for range in ${ranges[@]}; do
			if [[ "${range}" == *?- ]]; then
				start="${range%-}"
			elif [[ "${range}" == -?* ]]; then
				stop="${range#-}"
			elif [[ "${range}" == *?-?* ]]; then
				start="$(echo "${range}" | cut -d- -f1)"
				stop="$(echo "${range}" | cut -d- -f2)"
			else
				start="${range}"
				stop="${range}"
			fi
			matches=0
			do_start=0
			for i in 1 2; do
				versions="__DLANG_VERSIONS_$i[@]"
				for d_version in ${!versions}; do
					if [[ $do_start -eq 0 ]] && [[ "${d_version}" == "${start}" ]] || [[ -z "${start}" ]]; then
						do_start=1
					fi
					if [[ $do_start -eq 1 ]]; then
						valid[${d_version}]=1
						matches=$(( $matches+1 ))
					fi
					if [[ $do_start -eq 1 ]] && [[ "${d_version}" == "${stop}" ]]; then
						do_start=2
					fi
				done
				if [[ do_start -eq 1 ]] && [[ -n "${stop}" ]]; then
					die "Invalid end version in range '${range}'":
				fi
			done
			[[ $matches -ne 0 ]] || die "Range '${range}' matches no D versions"
		done
		__DLANG_VERSIONS=(${!valid[@]})
	fi

	# Convert D versions to usable compilers and write IUSE
	local slot compilers=() depends=()
	for d_version in ${__DLANG_VERSIONS[@]}; do
		# DMD
		case "${d_version}" in
			"2.063") slot="2.063" ;;
			"2.064") slot="2.064" ;;
			"2.065") slot="2.065" ;;
			*) slot="" ;;
		esac
		if [[ -n "${slot}" ]]; then
			compilers+=("dmd-$(replace_all_version_separators _ ${slot})")
			if [[ "${DLANG_PACKAGE_TYPE}" == "single" ]]; then
				depends+=("dmd-$(replace_all_version_separators _ ${slot})? ( dev-lang/dmd:${slot}= )")
			else
				depends+=("dmd-$(replace_all_version_separators _ ${slot})? ( dev-lang/dmd:${slot}=[${MULTILIB_USEDEP}] )")
			fi
		fi
		# GDC (doesn't support sub-slots, due to low EAPI requirement)
		case "${d_version}" in
			"2.063") slot="4.8.1" ;;
			"2.064") slot="4.8.2" ;;
			*) slot="" ;;
		esac
		if [[ -n "${slot}" ]]; then
			compilers+=("gdc-$(replace_all_version_separators _ ${slot})")
			depends+=("gdc-$(replace_all_version_separators _ ${slot})? ( =sys-devel/gcc-${slot}*[d] )")
		fi
		# LDC
		case "${d_version}" in
			"2.063") slot="0.12" ;;
			"2.064") slot="0.13" ;;
			"2.065") slot="0.14" ;;
			*) slot="" ;;
		esac
		if [[ -n "${slot}" ]]; then
			compilers+=("ldc2-$(replace_all_version_separators _ ${slot})")
			depends+=("ldc2-$(replace_all_version_separators _ ${slot})? ( dev-lang/ldc2:${slot}= )")
		fi
	done
	[[ ${#compilers[@]} -ne 0 ]] || die "No compilers found for D versions [${__DLANG_VERSIONS[@]}]"
	IUSE="${compilers[@]}"
	if [[ "${DLANG_PACKAGE_TYPE}" == "single" ]]; then
		REQUIRED_USE="^^ ( ${IUSE} )"
	else
		REQUIRED_USE="|| ( ${IUSE} )"
	fi
	DEPEND="${depends[@]}"
	RDEPEND="${depends[@]}"
}
__dlang_filter_versions

# We will need the real CHOST to find GDC and its library path.
__DLANG_CHOST="${CHOST}"

__dlang_phase_wrapper() {
	dlang_phase() {
		if declare -f d_src_${1} >/dev/null ; then
			d_src_${1}
		else
			default_src_${1}
		fi
	}

	if [[ ${DLANG_PACKAGE_TYPE} == "single" ]]; then
		dlang_single_config dlang_phase "${1}"
	else
		dlang_foreach_config dlang_phase "${1}"
	fi
}

__dlang_compiler_to_dlang_version() {
	local -rA gdc=(
		["4.8.1"]="2.063"
	)
	local -rA ldc=(
		["0.12"]="1.076"
	)
	local -rA ldc2=(
		["0.12"]="2.063"
		["0.13"]="2.064"
		["0.14"]="2.065"
	)

	case "${1}" in
	"dmd")
		echo "${2}"
		;;
	"gdc")
		echo "${gdc[${2}]}"
		;;
	"ldc")
		echo "${ldc[${2}]}"
		;;
	"ldc2")
		echo "${ldc2[${2}]}"
		;;
	*)
		die "Compiler '${1}' is unknown."
		;;
	esac
}

__dlang_build_configurations() {
	local variants=() use_flag
	for use_flag in ${USE}; do
		case ${use_flag} in
			dmd-* | gdc-* | ldc-* | ldc2-*)
				if [[ "${DLANG_PACKAGE_TYPE}" == "single" ]]; then
					variants+=("default-${use_flag//_/.}")
				else
					for abi in $(multilib_get_enabled_abis); do
						variants+=("${abi}-${use_flag//_/.}")
					done
				fi
				;;
		esac
	done
	if [ ${#variants[@]} -eq 0 ]; then
		die "At least one compiler USE-flag must be selected. This should be checked by REQUIRED_USE in this package."
	fi
	echo "${variants[@]}"
}

fi
