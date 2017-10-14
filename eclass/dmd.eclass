# @ECLASS: dmd.eclass
# @MAINTAINER: marco.leise@gmx.de
# @BLURB: Captures most of the logic for installing DMD
# @DESCRIPTION:
# Helps with the maintenance of the various DMD versions by capturing common
# logic.

if [[ ${___ECLASS_ONCE_DMD} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_DMD="recur -_+^+_- spank"

if has ${EAPI:-0} 0 1 2 3 4 5; then
	die "EAPI must be >= 6 for dmd packages."
fi

DESCRIPTION="Reference compiler for the D programming language"
HOMEPAGE="http://dlang.org/"
HTML_DOCS="html/*"

# DMD supports amd64/x86 exclusively
MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit multilib-build versionator

# For reliable download statistics, we don't mirror.
RESTRICT="mirror"
LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
MAJOR="$(get_major_version)"
MINOR="$((10#$(get_version_component_range 2)))"
PATCH="$(get_version_component_range 3)"
VERSION="$(get_version_component_range 1-3)"
BETA="$(get_version_component_range 4)"
if [ "${KERNEL}" != "FreeBSD" ]; then
	ARCHIVE="${ARCHIVE-linux.tar.xz}"
elif [ "${ARCH}" == "x86" ]; then
	ARCHIVE="${ARCHIVE-freebsd-32.tar.xz}"
else
	ARCHIVE="${ARCHIVE-freebsd-64.tar.xz}"
fi
SONAME="${SONAME-libphobos2.so.0.${MINOR}.${PATCH}}"
SONAME_SYM="${SONAME%.*}"

dmd_symlinkable() {
	# Return whether dmd will find dmd.conf in the executable directory, if we
	# call it through a symlink.
	[[ "${MAJOR}" -ge 2 ]] && [[ "${MINOR}" -ge 66 ]]
}

dmd_selfhosting() {
	# Return whether this dmd is self-hosting.
	[[ "${MAJOR}" -ge 2 ]] && [[ "${MINOR}" -ge 68 ]]
}

IUSE="doc examples static-libs tools"
if dmd_selfhosting; then
	DLANG_VERSION_RANGE="${DLANG_VERSION_RANGE-${SLOT}}"
	DLANG_PACKAGE_TYPE=dmd
	inherit dlang
fi

# Call EXPORT_FUNCTIONS after any imports
EXPORT_FUNCTIONS src_prepare src_compile src_test src_install pkg_postinst pkg_postrm

if [[ -n "${BETA}" ]]; then
	SRC_URI="http://downloads.dlang.org/pre-releases/${MAJOR}.x/${VERSION}/${PN}.${VERSION}-b${BETA:4}.${ARCHIVE}"
else
	SRC_URI="mirror://aws/${YEAR}/${PN}.${PV}.${ARCHIVE}"
fi

COMMON_DEPEND="
	net-misc/curl[${MULTILIB_USEDEP}]
	>=app-eselect/eselect-dlang-20140709
	"
DEPEND="
	${COMMON_DEPEND}
	app-arch/unzip
	"
RDEPEND="
	${COMMON_DEPEND}
	!dev-lang/dmd-bin
	"
PDEPEND="tools? ( >=dev-util/dlang-tools-${PV} )"

S="${WORKDIR}/dmd2"
PREFIX="opt/${PN}-${SLOT}"
IMPORT_DIR="/${PREFIX}/import"

dmd_abi_to_model() {
	[[ "${ABI:0:5}" == "amd64" ]] && echo 64 || echo 32
}

dmd_foreach_abi() {
	for ABI in $(multilib_get_enabled_abis); do
		local MODEL=$(dmd_abi_to_model)
		einfo "  Executing ${1} in ${MODEL}-bit ..."
		"${@}"
	done
}

dmd_src_prepare() {
	# Reorganize directories
	mkdir dmd || die "Failed to create directories 'dmd', 'druntime' and 'phobos'"
	mv src/dmd      dmd/src     || die "Failed to move 'src/dmd' to 'dmd/src'"
	mv src/VERSION  dmd/VERSION || die "Failed to move 'src/VERSION' to 'dmd/VERSION'"
	mv src/druntime druntime    || die "Failed to move 'src/druntime' to 'druntime'"
	mv src/phobos   phobos      || die "Failed to move 'src/phobos' to 'phobos'"
	# Symlinks used by dmd in the selfhosting case
	ln -s ../druntime src/druntime || die "Failed to symlink 'druntime' to 'src/druntime'"
	ln -s ../phobos   src/phobos   || die "Failed to symlink 'phobos' to 'src/phobos'"

	# Convert line-endings of file-types that start as cr-lf and are installed later on
	for file in $( find . -name "*.txt" -o -name "*.html" -o -name "*.d" -o -name "*.di" -o -name "*.ddoc" -type f ); do
		edos2unix $file || die "Failed to convert DOS line-endings to Unix."
	done

	# Ebuild patches
	if [ -n "${PATCHES}" ]; then
		for p in "${PATCHES}"; do
			eapply "${FILESDIR}/${p}"
		done
	fi

	# Run other preparations
	declare -f dmd_src_prepare_extra > /dev/null && dmd_src_prepare_extra

	# User patches
	eapply_user
}

dmd_src_compile() {
	# A native build of dmd is used to compile the runtimes for both x86 and amd64
	# We cannot use multilib-minimal yet, as we have to be sure dmd for amd64
	# always gets build first.
	einfo "Building dmd..."

	# 2.068 used HOST_DC instead of HOST_DMD
	[[ "${SLOT}" == "2.068" ]] && HOST_DMD="HOST_DC" || HOST_DMD="HOST_DMD"
	# 2.072 and 2.073 have support for LTO, but would need a Makefile patch
	[[ "${SLOT}" != "2.072" && "${SLOT}" != "2.073" ]] && LTO="ENABLE_LTO=1"

	# Special case for self-hosting (i.e. no compiler USE flag selected).
	local kernel model
	if [ "${DC_VERSION}" == "selfhost" ]; then
		case "${KERNEL}" in
			"linux")   kernel="linux";;
			"FreeBSD") kernel="freebsd";;
			*) die "Self-hosting dmd on ${KERNEL} is not currently supported."
		esac
		case "${ARCH}" in
			"x86")   model=32;;
			"amd64") model=64;;
			*) die "Self-hosting dmd on ${ARCH} is not currently supported."
		esac
		export DMD="../../${kernel}/bin${model}/dmd"
	fi
	emake -C dmd/src -f posix.mak TARGET_CPU=X86 ${HOST_DMD}="${DMD}" RELEASE=1 ${LTO}

	# Don't pick up /etc/dmd.conf when calling dmd/src/dmd !
	if [ ! -f dmd/src/dmd.conf ]; then
		einfo "Creating a dummy dmd.conf"
		touch dmd/src/dmd.conf || die "Could not create dummy dmd.conf"
	fi

	compile_libraries() {
		einfo 'Building druntime...'
		emake -C druntime -f posix.mak DMD=../dmd/src/dmd MODEL=${MODEL} PIC=1 MANIFEST=

		einfo 'Building Phobos 2...'
		emake -C phobos -f posix.mak DMD=../dmd/src/dmd MODEL=${MODEL} PIC=1 CUSTOM_DRUNTIME=1
	}

	dmd_foreach_abi compile_libraries

	# Not needed after compilation. Would otherwise be installed as imports.
	rm -r phobos/etc/c/zlib
}

dmd_src_test() {
	test_hello_world() {
		dmd/src/dmd -m${MODEL} -fPIC -Iphobos -Idruntime/import -L-Lphobos/generated/linux/release/${MODEL} samples/d/hello.d || die "Failed to build hello.d (${MODEL}-bit)"
		./hello ${MODEL}-bit || die "Failed to run test sample (${MODEL}-bit)"
		rm hello.o hello || die "Could not remove temporary files"
	}

	dmd_foreach_abi test_hello_world
}

dmd_src_install() {
	local MODEL=$(dmd_abi_to_model)

	# dmd.conf
	if has_multilib_profile; then
		cat > linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2 -fPIC
[Environment32]
DFLAGS=%DFLAGS% -L-L/${PREFIX}/lib32 -L-rpath -L/${PREFIX}/lib32
[Environment64]
DFLAGS=%DFLAGS% -L-L/${PREFIX}/lib64 -L-rpath -L/${PREFIX}/lib64
EOF
	elif [ "${ABI:0:5}" = "amd64" ]; then
		cat > linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2 -L-L/${PREFIX}/lib64 -L-rpath -L/${PREFIX}/lib64
EOF
	else
		cat > linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2 -fPIC -L-L/${PREFIX}/lib -L-rpath -L/${PREFIX}/lib
EOF
	fi
	insinto "etc/dmd"
	newins "linux/bin${MODEL}/dmd.conf" "${SLOT}.conf"
	dosym "../../../etc/dmd/${SLOT}.conf" "${PREFIX}/bin/dmd.conf"

	# DMD
	einfo "Installing ${PN}..."
	dmd_symlinkable && dosym "../../${PREFIX}/bin/dmd" "${ROOT}/usr/bin/dmd-${SLOT}"
	into ${PREFIX}
	dobin "dmd/src/dmd"

	# druntime
	einfo 'Installing druntime...'
	insinto ${PREFIX}
	doins -r druntime/import

	# Phobos 2
	einfo 'Installing Phobos 2...'
	into usr
	install_phobos_2() {
		# Copied get_libdir logic from dlang.eclass, so we can install Phobos correctly.
		if has_multilib_profile || [[ "${MODEL}" == "64" ]]; then
			local libdir="../opt/dmd-${SLOT}/lib${MODEL}"
		else
			local libdir="../opt/dmd-${SLOT}/lib"
		fi

		# Install shared lib.
		dolib.so phobos/generated/linux/release/${MODEL}/"${SONAME}"
		dosym "${SONAME}" /usr/"$(get_libdir)"/"${SONAME_SYM}"
		dosym ../../../usr/"$(get_libdir)"/"${SONAME}" /usr/"${libdir}"/libphobos2.so

		# Install static lib if requested.
		if use static-libs; then
			if has_multilib_profile || [[ "${MODEL}" == "64" ]]; then
				export LIBDIR_${ABI}="../opt/dmd-${SLOT}/lib${MODEL}"
			else
				export LIBDIR_${ABI}="../opt/dmd-${SLOT}/lib"
			fi
			dolib.a phobos/generated/linux/release/${MODEL}/libphobos2.a
		fi
	}
	dmd_foreach_abi install_phobos_2
	insinto ${PREFIX}/import
	doins -r phobos/{etc,std}

	# man pages, docs and samples
	insinto ${PREFIX}/man/man1
	doins man/man1/dmd.1
	insinto ${PREFIX}/man/man5
	doins man/man5/dmd.conf.5
	if use doc; then
		einstalldocs
		insinto "/usr/share/doc/${PF}/html"
		doins "${FILESDIR}/dmd-doc.png"
		make_desktop_entry "xdg-open ${ROOT}usr/share/doc/${PF}/html/d/index.html" "DMD ${PV}" "${ROOT}usr/share/doc/${PF}/html/dmd-doc.png" "Development"
	fi
	if use examples; then
		insinto ${PREFIX}/samples
		doins -r samples/d/*
		docompress -x ${PREFIX}/samples/
	fi
}

dmd_pkg_postinst() {
	# Update active dmd
	"${ROOT}"/usr/bin/eselect dlang update dmd

	use examples && elog "Examples can be found in: /${PREFIX}/samples"
	use doc && elog "HTML documentation is in: /usr/share/doc/${PF}/html"
}

dmd_pkg_postrm() {
	"${ROOT}"/usr/bin/eselect dlang update dmd
}

fi
