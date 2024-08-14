# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dub.eclass
# @MAINTAINER:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# @AUTHOR:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# @BUGREPORTS:
# Please report bugs via https://github.com/gentoo/dlang/issues
# @VCSURL: https://github.com/gentoo/dlang
# @SUPPORTED_EAPIS: 8
# @BLURB: common functions and variables for dub builds
# @DESCRIPTION:
# This eclass provides a wrapper for calling dub as well as default
# implementations for src_compile and src_test.  It also provides
# dub_src_unpack which will make dub dependencies available as well
# as configure it to work best in an ebuild environment.
#
# By default this eclass will set *DEPEND to depend on both dub and a D
# compiler.  For this reason you *must* inherit either dlang-single or
# dlang-r1 before inheriting dub.  The only alternative is using
# DUB_OPTIONAL.
# @EXAMPLE:
# A program using dub.eclass:
#
# @CODE
# DLANG_COMPAT=( dmd-2_109 gdc-1{3,4} ldc2-1_39 )
# DUB_DEPENDENCIES=(
#     "automem@0.6.9"
#     "cachetools@0.4.1"
#     "dcd@0.16.0-beta.2"
#     "program@8.0.3"
#     "silly@1.1.1"
# )
# inherit dlang-single dub
# SRC_URI="${DUB_DEPENDENCIES_URIS}"
#
# src_install() {
#     dobin "${S}/program"
# }
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ ! ${_DUB_ECLASS} ]]; then
_DUB_ECLASS=1

inherit dlang-utils edo

# @ECLASS_VARIABLE: DUB_DEPEND
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Dependency string on dev-util/dub and other needed programs that can
# be used in BDEPEND when DUB_OPTIONAL is set.  When DUB_OPTIONAL is
# empty the dependency is added automatically to BDEPEND.
DUB_DEPEND=">=dev-util/dub-1.38.0 app-arch/unzip"
# 1.38 - respect skipRegistry value in configuration file

EDUB_HOME="${WORKDIR}/dub_home"

# @ECLASS_VARIABLE: DUB_OPTIONAL
# @DEFAULT_UNSET
# @PRE_INHERIT
# @DESCRIPTION:
# Setting this to a non-empty value inhibits the eclass from modifying
# variables like *DEPEND and REQUIRED_USE and from exporting phase
# functions.
#
# If set, you may need to call dub_gen_settings or dub_src_unpack
# manually.

# @ECLASS_VARIABLE: DUB_DEPENDENCIES
# @DEFAULT_UNSET
# @PRE_INHERIT
# @DESCRIPTION:
# A bash array of dub dependencies.  Each dependency should be a string
# in the form `name@version`.
#
# Example:
# @CODE
# DUB_DEPENDENCIES=(
#     "dfmt@0.15.1"
#     "silly@1.1.1"
# )
# @CODE

# @ECLASS_VARIABLE: DUB_DEPENDENCIES_URIS
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# The transformed DUB_DEPENDENCIES as a string to be placed in
# SRC_URI

# @FUNCTION: dub_dependencies_uris
# @USAGE: [dependencies]...
# @DESCRIPTION:
# print a string to be placed in SRC_URI for all the dependencies given
# as arguments.  Each dependency should be in the form `name@version`,
# just like the elements in DUB_DEPENDENCIES.
dub_dependencies_uris() {
	debug-print-function ${FUNCNAME} "${@}"

	local registry="https://code.dlang.org/packages"
	local dep name ver
	for dep; do
		name="${dep%@*}"
		ver="${dep#*@}"
		echo "${registry}/${name}/${ver}.zip -> ${name}-${ver}.zip"
	done
}

# @FUNCTION: _handle_dub_variables
# @INTERNAL
# @DESCRIPTION:
# Verify that DUB_DEPENDENCIES is set appropriately, transform it into
# DUB_DEPENDENCIES_URIS, and set any other variables.
_handle_dub_variables() {
	[[ -v DUB_DEPENDENCIES && ${DUB_DEPENDENCIES@a} != *a* ]] \
		&& die "DUB_DEPENDENCIES must be an array"
	export DUB_DEPENDENCIES_URIS="$(dub_dependencies_uris "${DUB_DEPENDENCIES[@]}")"

	[[ ${DUB_OPTIONAL} ]] && return

	if ! has dlang-single ${INHERITED} && ! has dlang-r1 ${INHERITED}; then
		eerror
		eerror "dlang-single or dlang-r1 have not been inherited before dub.eclass"
		eerror "and DUB_OPTIONAL has not been set."
		eerror "Please inherit dlang-single or dlang-r1 before inheriting dub."
		die "Neither dlang-single nor dlang-r1 are inherited"
	fi

	[[ ${CATEGORY}/${PN} != dev-util/dub ]] \
		&& BDEPEND="${DUB_DEPEND}"

	BDEPEND+=" ${DLANG_DEPS}"
	DEPEND="${DLANG_DEPS}"
	RDEPEND="${DLANG_DEPS}"
	REQUIRED_USE="${DLANG_REQUIRED_USE}"
}
_handle_dub_variables
unset -f _handle_dub_variables

# @FUNCTION: edub
# @USAGE: [dub_args]...
# @DESCRIPTION:
# A dub wrapper that will automatically set relevant variables and die
# on failure.  nonfatal can be used with edub.
#
# Meaningful variables for this function are:
#
# $DC - typically set by dlang-r1.eclass or dlang-single.eclass to point
# to the D compiler and respected by dub.
#
# $DFLAGS - dub will use these flags when compiling + linking.  If the
# variable is unset (empty does not count) this eclass will default to
# "${DCFLAGS} ${DLANG_LDFLAGS} /-Wno-error/" for its value.
#
# $NO_COLOR - if non-empty dub will not print colors
edub() {
	debug-print-function ${FUNCNAME} "${@}"

	local -x DFLAGS=${DFLAGS-${DCFLAGS} ${DLANG_LDFLAGS} $(dlang_get_wno_error_flag)}
	local -x DC=${DC} NO_COLOR=${NO_COLOR}
	# FIXME dub directly calls pkg-config without a way to configure it

	debug-print "${FUNCNAME}: DC=${DC}"
	debug-print "${FUNCNAME}: DFLAGS=${DFLAGS}"

	edo dub --verbose "${@}"
}

# @ECLASS_VARIABLE: DUB_LOCAL_REGISTRY
# @DESCRIPTION:
# A directory in which dub package archives can be placed for dub to be
# able to fetch them in the future.  This is useful only if dub _must_
# perform a fetch operation, perhaps as part of tests, in all other
# cases DUB_DEPENDENCIES should be used instead.
#
# You can use dub_copy_dependencies_locally as a convenience function.
#
# Example:
# @CODE
# src_unpack() {
#   dub_src_unpack
#   use test && dub_copy_dependencies_locally "my_packages@1.1.0"
# }
# src_test() {
#   dub_src_test
#
#   # additional test that performs `dub fetch my_package@1.1.0`
# }
# @CODE
DUB_LOCAL_REGISTRY="${EDUB_HOME}/local_registry"

# @FUNCTION: dub_copy_dependencies_locally
# @USAGE: [dependencies]...
# @DESCRIPTION:
# Copy the given dependencies to ${DUB_LOCAL_REGISTRY}.  This function
# can only be called inside src_unpack.
#
# The format of the arguments is the same as the format of
# ${DUB_DEPENDENCIES}.
dub_copy_dependencies_locally() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${EBUILD_PHASE} == unpack ]] \
		|| die "${FUNCNAME} must only be called inside src_unpack"

	local dep
	for dep; do
		einfo "Making ${dep} available locally"
		cp "${DISTDIR}/${dep/@/-}.zip" "${DUB_LOCAL_REGISTRY}" || die
	done
}

# @FUNCTION: dub_gen_settings
# @DESCRIPTION:
# Generate a settings.json file for dub.
dub_gen_settings() {
	debug-print-function ${FUNCNAME} "${@}"

	mkdir -p "${EDUB_HOME}" || die "Could not create dub home directory"
	mkdir -p "${DUB_LOCAL_REGISTRY}" || die "Could not create dub registry directory"

	# dub merges the settings from all configuration files so settings
	# which greatly change the build need to be set to a safe
	# value. Unfortunately the 'customCachePaths' and 'registryUrls'
	# settings are cumulative, i.e. they will append to the previous
	# value, not overwrite it.
	cat > "${EDUB_HOME}/settings.json" <<-EOF || die "Failed to create dub settings.json file"
	{
		"registryUrls": [
			"file://${DUB_LOCAL_REGISTRY}"
		],
		"skipRegistry": "standard",

		"customCachePaths": [],
		"defaultCompiler": "",
		"defaultArchitecture": ""
	}
	EOF

	export DUB_HOME="${EDUB_HOME}"
}

# @FUNCTION: dub_src_unpack
# @DESCRIPTION:
# Unpack all sources and generate a dub configuration file
dub_src_unpack() {
	dub_gen_settings

	# DUB_DEPENDENCIES can contain entries like:
	# dfmt@0.15.1 which maps to the archive dmft-0.15.1.zip
	#
	# There can also be dependencies like:
	# botan-math@1.0.4 -> botan-math-1.0.4.zip
	# botan@1.13.6 -> botan-1.13.6.zip
	#
	# Because of the ambiguous `-' character create a map
	# from the archive back to the dependency.
	local -A dubFiles
	local dep
	for dep in "${DUB_DEPENDENCIES[@]}"; do
		dubFiles["${dep/@/-}.zip"]="${dep}"
	done

	local dubFetch=(
		dub
		--skip-registry=all
		--registry="file://${DISTDIR}"
		fetch
	)
	local dep file
	for file in ${A}; do
		if [[ ${dubFiles[${file}]} ]]; then
			# file can be 'dfmt-0.15.1.zip'
			# in which case dubFiles[${file}] wil be 'dfmt@0.15.1'
			dep="${dubFiles[${file}]}"
			edo "${dubFetch[@]}" "${dep}"

			# If it's the main package extract it for ${S}.
			# In case of prereleases:
			# serve-d-0.8.0_beta17 -> serve-d-0.8.0-beta.17.zip
			[[ ${file} == ${PN}-$(ver_rs 3 - 4 .)* ]] \
				&& unpack "${file}"
		else
			unpack "${file}"
		fi
	done
}

# @FUNCTION: dub_src_compile
# @DESCRIPTION:
# Compile the package using dub
dub_src_compile() {
	edub build
}

# @FUNCTION: dub_src_test
# @DESCRIPTION:
# Test the package using dub
dub_src_test() {
	edub test
}

fi

[[ ${DUB_OPTIONAL} ]] \
	|| EXPORT_FUNCTIONS src_unpack src_compile src_test
