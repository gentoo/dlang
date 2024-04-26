# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dmd-r1.eclass
# @MAINTAINER:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# @AUTHOR:
# Andrei Horodniceanu <a.horodniceanu@proton.me>
# Based on dmd.eclass by Marco Leise <marco.leise@gmx.de>.
# @BUGREPORTS:
# Please report bugs via https://github.com/gentoo/dlang/issues
# @VCSURL: https://github.com/gentoo/dlang
# @SUPPORTED_EAPIS: 8
# @BLURB: Captures most of the logic for building and installing DMD
# @DESCRIPTION:
# Helps with the maintenance of the various DMD versions by capturing common
# logic.

if [[ ! ${_ECLASS_ONCE_DMD_R1} ]] ; then
_ECLASS_ONCE_DMD_R1=1

case ${EAPI:-0} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

DESCRIPTION="Reference compiler for the D programming language"
HOMEPAGE="https://dlang.org/"

# DMD supports amd64/x86 exclusively
# @ECLASS_VARIABLE: MULTILIB_COMPAT
# @DESCRIPTION:
# A list of multilib ABIs supported by $PN. It only supports
# abi_x86_{32,64}. See the multilib-build.eclass documentation for this
# variable for more information.
MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit desktop edos2unix dlang-single multilib-build multiprocessing optfeature

LICENSE=Boost-1.0
SLOT=$(ver_cut 1-2)
readonly MAJOR=$(ver_cut 1)
readonly MINOR=$(ver_cut 2)
readonly PATCH=$(ver_cut 3)
readonly VERSION=$(ver_cut 1-3)
readonly BETA=$(ver_cut 4-)

# For prereleases, 2.097.0_rc1 -> 2.097.0-rc.1
MY_VER=$(ver_rs 3 - 4 .)

DLANG_ORG=https://downloads.dlang.org/${BETA:+pre-}releases/2.x/${VERSION}
SRC_URI="
	https://github.com/dlang/${PN}/archive/refs/tags/v${MY_VER}.tar.gz -> ${PN}-${MY_VER}.tar.gz
	https://github.com/dlang/phobos/archive/refs/tags/v${MY_VER}.tar.gz -> phobos-${MY_VER}.tar.gz
	selfhost? ( ${DLANG_ORG}/dmd.${MY_VER}.linux.tar.xz )
	doc? ( ${DLANG_ORG}/dmd.${MY_VER}.linux.tar.xz )
"

IUSE="doc examples +selfhost static-libs"
REQUIRED_USE="^^ ( selfhost ${DLANG_REQUIRED_USE} )"
IDEPEND=">=app-eselect/eselect-dlang-20140709"
BDEPEND="!selfhost? ( ${DLANG_DEPS} )"
# We don't need anything in DEPEND, curl is dl-opened
# so it belongs in RDEPEND.
#DEPEND=
# Since 2.107.0, dmd links the standard library of the host
# compiler. Since this eclass is only used by >=dmd-2.107.0-r1 the
# dependency is added unconditionally.
RDEPEND="
	${IDEPEND}
	net-misc/curl[${MULTILIB_USEDEP}]
	!selfhost? ( ${DLANG_DEPS} )
"

dmd-r1_pkg_setup() {
	if use !selfhost; then
		dlang-single_pkg_setup
		# set by dlang-single.eclass:
		# $EDC, $DC, $DLANG_LDFLAGS, $DCFLAGS

		# Now let's build our environment
		export DMDW=$(dlang_get_dmdw)
		export DMDW_DCFLAGS=$(dlang_get_dmdw_dcflags)
		export DMDW_LDFLAGS=$(dlang_get_dmdw_ldflags)
	else
		# Setup up similar variables to the above
		export EDC=dmd-${SLOT}
		#export DC= # is set inside src_unpack
		#export DMDW= # is set inside src_unpack
		export DLANG_LDFLAGS=$(dlang_get_ldflags)
		# Should we put user DMDFLAGS here?
		export DMDW_DCFLAGS= DCFLAGS=
		export DMDW_LDFLAGS=$(dlang_get_dmdw_ldflags)
	fi
}

dmd-r1_src_unpack() {
	# Here because pkgdev complains about it being in pkg_setup
	if use selfhost; then
		export DC=${WORKDIR}/dmd2/linux/bin$(dlang_get_abi_bits)/dmd
		export DMDW=${DC}
	fi

	default

	# $S may collide with $PN-$MY_VER
	mv "${PN}-${MY_VER}" tmp || die
	mkdir "${S}" || die
	mv -T tmp "${S}/${PN}" || die
	mv -T "phobos-${MY_VER}" "${S}/phobos" || die
}

dmd-r1_src_prepare() {
	einfo "Removing dos-style line endings."
	local file
	while read -rd '' file; do
		edos2unix "${file}"
	done < <( find "${WORKDIR}" \( -name '*.txt' -o -name '*.html' -o -name '*.d' \
				   -o -name '*.di' -o -name '*.ddoc' -type f \) \
				   -print0 )

	default
}

dmd-r1_src_compile() {
	einfo "Building dmd build script"
	dlang_compile_bin dmd/compiler/src/build{,.d}
	local BUILD_D=${S}/dmd/compiler/src/build

	local cmd=(
		env
		VERBOSE=1
		HOST_DMD="${DMDW}"
		# Just like old dmd.eclass.
		#
		# TODO, this has to be fixed but right now we either do
		# ENABLE_RELEASE (we add -O -inline -release) or build.d will
		# add -g.
		ENABLE_RELEASE=1
		"${BUILD_D}"
		-j$(makeopts_jobs)
		# A bit overkill to specify the flags here but it does get the
		# jobs done.
		DFLAGS="${DMDW_DCFLAGS} ${DMDW_LDFLAGS}"
	)

	einfo "Building dmd"
	echo "${cmd[@]}"
	"${cmd[@]}" || die "Failed to build dmd"

	# The release here is from ENABLE_RELEASE, keep them in sync.
	export GENERATED_DMD=${S}/dmd/generated/linux/release/$(dlang_get_abi_bits)/dmd

	compile_libraries() {
		local commonMakeArgs=(
			DMD="${GENERATED_DMD}"
			MODEL=${MODEL}

			# Just like how multilib_toolchain_setup does it:
			CC="$(tc-getCC) $(get_abi_CFLAGS)"
			# The flags are, a little, project dependent
			#CFLAGS=

			# With DFLAGS we have 2 problems:
			#
			# 1. it's pretty hard to specify them for druntime so
			#    it would need a makefile patch
			#
			# 2. we have the same question as in pkg_setup, do we
			#    respect DMDFLAGS when building with the generated dmd?
			#
			#DFLAGS=
		)
		local druntimeMakeArgs=(
			# Calls git in global scope, only used for whitespace checks.
			MANIFEST=

			# Specifying user flags here discards the, hopefully
			# relevant, values from the makefile so add them back.
			CFLAGS="${CFLAGS} -fPIC -DHAVE_UNISTD_H" # -m32/64 is added in $CC.

			# druntime's notion of a shared library is a static archive
			# that is embedded into the phobos shared library.
			#
			# Technically there is the dll_so target which is the proper
			# so file but who's gonna use it? Perhaps if phobos would
			# not incorporate druntime we could install them as separate
			# libraries (like ldc2 and gdc).
			$(usex static-libs 'lib dll' dll)

			# We also need to copy the headers to the proper location
			import
		)
		local phobosMakeArgs=(
			# If unspecified, would rebuild druntime.
			CUSTOM_DRUNTIME=1

			# Like druntime, specifying flags removes the makefile added ones.
			#
			# Since 2.108.0 -DHAVE_UNISTD_H is handled by CPPFLAGS => we
			# don't need to specify it here.
			CFLAGS="${CFLAGS} -fPIC -std=c11 -DHAVE_UNISTD_H" # -m32/64 is added in $CC.

			# Overkill but it does work. Remember that we have to
			# convert $LDFLAGS to something dmd understands.
			DFLAGS="$(dlang_get_ldflags ${PN}-${SLOT})"

			# By default builds both static+dynamic libraries.
			$(usex static-libs 'lib dll' dll)
		)
		# Prefer compiling C files with CC, not with dmd. (USE_IMPORTC=1
		# adds dependency on libdruntime.a)
		ver_test -ge 2.108.0 && phobosMakeArgs+=( "USE_IMPORTC=0" )

		emake -C dmd/druntime "${commonMakeArgs[@]}" "${druntimeMakeArgs[@]}"
		emake -C phobos "${commonMakeArgs[@]}" "${phobosMakeArgs[@]}"
	}

	_dmd_foreach_abi compile_libraries

	# Build the man pages
	local cmd=(
		env
		VERBOSE=1
		HOST_DMD="${GENERATED_DMD}"
		"${BUILD_D}"
		-j$(makeopts_jobs)
		man
		# ${GENERATED_DMD} is not yet fully functional as we didn't
		# create a good dmd.conf. But instead of doing that we're going
		# to specify our flags here.
		DFLAGS="-defaultlib=phobos2 -L-rpath=${S}/phobos/generated/linux/release/$(dlang_get_abi_bits)"
	)
	echo "${cmd[@]}"
	"${cmd[@]}" || die "Could not generate man pages"

	# Now clean up some artifacts that would make the install phase
	# harder (we rely on globbing and recursive calls a lot).

	# The object file is useless
	rm -f phobos/generated/linux/release/*/libphobos2.so.0.${MINOR}.o || die
	# the zlib folder contains source code which is no longer
	# needed. Don't touch etc/c/zlib.d however, that's important.
	rm -rf phobos/etc/c/zlib || die
}

dmd-r1_src_test() {
	# As opposed to old dmd.eclass we have access to actual tests. For
	# porting reasons we're going to keep only the old test,
	# hello_world.

	test_hello_world() {
		local phobosDir=${S}/phobos/generated/linux/release/${MODEL}
		local commandArgs=(
			# Copied from _gen_dmd.conf
			-L--export-dynamic
			-defaultlib=phobos2 # If unspecified, defaults to libphobos2.a
			-fPIC
			-L-L"${phobosDir}"
			-L-rpath="${phobosDir}"

			-conf= # Don't use dmd.conf
			-m${MODEL}
			-Iphobos
			-Idmd/druntime/import
		)

		"${GENERATED_DMD}" "${commandArgs[@]}" dmd/compiler/samples/hello.d \
			|| die "Failed to build hello.d (${MODEL}-bit)"
		./hello ${MODEL}-bit || die "Failed to run test sample (${MODEL}-bit)"
	}

	_dmd_foreach_abi test_hello_world

}

dmd-r1_src_install() {
	local EDC=${PN}-${SLOT} # overwrite the one from pkg_setup
	local dmd_prefix=/usr/lib/${PN}/$(dlang_get_be_version)

	dodir /etc/dmd
	_gen_dmd.conf > "${ED}"/etc/dmd/${SLOT}.conf || die "Could not generate dmd.conf"
	# Put a symlink to dmd.conf into the same folder as the dmd
	# executable so it gets picked up automatically (and instead of
	# /etc/dmd.conf).
	dosym -r "/etc/dmd/${SLOT}.conf" "${dmd_prefix}/bin/dmd.conf"

	into "${dmd_prefix}"
	dobin "${GENERATED_DMD}"
	dosym -r "${dmd_prefix}/bin/dmd" "/usr/bin/dmd-${SLOT}"

	insinto "${dmd_prefix}"
	doins -r dmd/druntime/import

	# Old dmd.eclass installed the so to $(get_libdir) and symlinked it
	# into ${dmd_prefix}. We do it the other way around.
	install_phobos_2() {
		local G=phobos/generated/linux/release/${MODEL}
		into /usr

		dlang_dolib.so "${G}"/libphobos2.so*
		use static-libs && dlang_dolib.a "${G}"/libphobos2.a

		# The symlinks under $(get_libdir) are only for backwards
		# compatibility purposes.
		local filename=libphobos2.so.0.${MINOR}
		dosym -r "/usr/$(dlang_get_libdir)/${filename}" "/usr/$(get_libdir)/${filename}"
		dosym -r "/usr/$(dlang_get_libdir)/${filename}.${PATCH}" "/usr/$(get_libdir)/${filename}.${PATCH}"
	}
	_dmd_foreach_abi install_phobos_2
	insinto "${dmd_prefix}"/import
	doins -r phobos/{etc,std}

	insinto "${dmd_prefix}"/man/man1
	doins dmd/generated/docs/man/man1/dmd.1
	insinto "${dmd_prefix}"/man/man5
	doins dmd/generated/docs/man/man5/dmd.conf.5

	if use examples; then
		insinto "${dmd_prefix}"/samples
		doins -r dmd/compiler/samples/*
		docompress -x "${dmd_prefix}"/samples
	fi

	if use doc; then
		HTML_DOCS=( "${WORKDIR}"/dmd2/html/* )
		einstalldocs
		insinto "/usr/share/doc/${PF}/html"
		doins "${FILESDIR}/dmd-doc.png"
		make_desktop_entry "xdg-open ${EPREFIX}/usr/share/doc/${PF}/html/d/index.html" \
						   "DMD ${PV}" \
						   "${EPREFIX}/usr/share/doc/${PF}/html/dmd-doc.png" \
						   "Development"
	fi
}

dmd-r1_pkg_postinst() {
	"${EROOT}"/usr/bin/eselect dlang update dmd

	use examples &&
		elog "Examples can be found in: ${EPREFIX}/usr/lib/${PN}/${SLOT}/samples"
	use doc && elog "HTML documentation is in: ${EPREFIX}/usr/share/doc/${PF}/html"

	optfeature "additional D development tools" "dev-util/dlang-tools"
}

dmd-r1_pkg_postrm() {
	"${ERROT}"/usr/bin/eselect dlang update dmd
}

# @FUNCTION: _gen_dmd.conf
# @INTERNAL
# @DESCRIPTION:
# Print a dmd.conf to be installed on the user system. Needs $EDC to be
# set up up beforehand.
_gen_dmd.conf() {
	debug-print-function ${FUNCNAME} "${@}"

	# Note, the logic for which libdir is used is all kept in
	# dlang-utils.eclass in order not to duplicate code.

	local import_dir=${EPREFIX}/usr/lib/${PN}/$(dlang_get_be_version)/import
	# Should this, instead, check which ABIs have been enabled?
	if has_multilib_profile; then
		local libdir_amd64=${EPREFIX}/usr/$(ABI=amd64 dlang_get_libdir)
		local libdir_x86=${EPREFIX}/usr/$(ABI=x86 dlang_get_libdir)
		cat <<EOF
[Environment]
DFLAGS=-I${import_dir} -L--export-dynamic -defaultlib=phobos2 -fPIC
[Environment32]
DFLAGS=%DFLAGS% -L-L${libdir_x86} -L-rpath=${libdir_x86}
[Environment64]
DFLAGS=%DFLAGS% -L-L${libdir_amd64} -L-rpath=${libdir_amd64}
EOF

	else
		local libdir=${EPREFIX}/usr/$(dlang_get_libdir)
		cat <<EOF
[Environment]
DFLAGS=-I${import_dir} -L--export-dynamic -defaultlib=phobos2 -fPIC -L-L${libdir} -L-rpath=${libdir}
EOF

	fi
}

# @FUNCTION: _dmd_foreach_abi
# @USAGE: <cmd> [<args>...]
# @INTERNAL
# @DESCRIPTION:
# Run a command for each enabled ABI, similar to multilib_foreach_abi but
# without setting $BUILD_DIR. Sets up $ABI and $MODEL (bits)
# appropriately.
_dmd_foreach_abi() {
	debug-print-function ${FUNCNAME} "${@}"

	local ABI
	for ABI in $(multilib_get_enabled_abis); do
		local MODEL=$(dlang_get_abi_bits)
		einfo "Executing ${1} in ${MODEL}-bit"
		"${@}"
	done
}

fi

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_compile src_test src_install \
				 pkg_postinst pkg_postrm
