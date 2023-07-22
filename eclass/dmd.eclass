# @ECLASS: dmd.eclass
# @MAINTAINER:
# Marco Leise <marco.leise@gmx.de>
# @BLURB: Captures most of the logic for installing DMD
# @DESCRIPTION:
# Helps with the maintenance of the various DMD versions by capturing common
# logic.

if [[ ${_ECLASS_ONCE_DMD} != "recur -_+^+_- spank" ]] ; then
_ECLASS_ONCE_DMD="recur -_+^+_- spank"

if has ${EAPI:-0} 0 1 2 3 4 5; then
	die "EAPI must be >= 6 for dmd packages."
fi

DESCRIPTION="Reference compiler for the D programming language"
HOMEPAGE="http://dlang.org/"
HTML_DOCS="html/*"

# DMD supports amd64/x86 exclusively
MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit multilib-build eapi7-ver toolchain-funcs

dmd_eq() {
	[[ ${MAJOR} -eq ${1%.*} ]] && [[ ${MINOR} -eq $((10#${1#*.})) ]]
}

dmd_ge() {
	[[ ${MAJOR} -ge ${1%.*} ]] && [[ ${MINOR} -ge $((10#${1#*.})) ]]
}

dmd_gen_exe_dir() {
	if dmd_ge 2.074; then
		echo dmd/generated/linux/release/$(dmd_arch_to_model)
	else
		echo dmd/src
	fi
}

# For reliable download statistics, we don't mirror.
RESTRICT="mirror"
LICENSE="Boost-1.0"
SLOT="$(ver_cut 1-2)"
MAJOR="$(ver_cut 1)"
MINOR="$((10#$(ver_cut 2)))"
PATCH="$(ver_cut 3)"
VERSION="$(ver_cut 1-3)"
BETA="$(ver_cut 4)"
if [ "${KERNEL}" != "FreeBSD" ]; then
	ARCHIVE="${ARCHIVE-linux.tar.xz}"
elif [ "${ARCH}" == "x86" ]; then
	ARCHIVE="${ARCHIVE-freebsd-32.tar.xz}"
else
	ARCHIVE="${ARCHIVE-freebsd-64.tar.xz}"
fi
SONAME="${SONAME-libphobos2.so.0.${MINOR}.${PATCH}}"
SONAME_SYM="${SONAME%.*}"

IUSE="doc examples static-libs tools"

# Self-hosting versions of DMD need a host compiler.
if dmd_ge 2.068; then
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
PREFIX="usr/lib/${PN}/${SLOT}"
IMPORT_DIR="/${PREFIX}/import"

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

	mkdir dmd/generated || die "Could not create output directory"

	# Convert line-endings of file-types that start as cr-lf and are installed later on
	for file in $( find . -name "*.txt" -o -name "*.html" -o -name "*.d" -o -name "*.di" -o -name "*.ddoc" -type f ); do
		edos2unix $file || die "Failed to convert DOS line-endings to Unix."
	done

	# Ebuild patches
	default

	# Run other preparations
	declare -f dmd_src_prepare_extra > /dev/null && dmd_src_prepare_extra

	# User patches
	eapply_user
}

dmd_src_compile() {
	# A native build of dmd is used to compile the runtimes for both x86 and amd64
	# We cannot use multilib-minimal yet, as we have to be sure dmd for amd64
	# always gets build first.

	# 2.068 used HOST_DC instead of HOST_DMD
	dmd_eq 2.068 && HOST_DMD="HOST_DC" || HOST_DMD="HOST_DMD"
	# 2.070 and below used HOST_CC instead of HOST_CXX
	dmd_ge 2.071 && HOST_CXX="HOST_CXX" || HOST_CXX="HOST_CC"
	# 2.072 and 2.073 have support for LTO, but would need a Makefile patch.
	# From 2.088 on, the build fails with it active.
	dmd_ge 2.074 && ! dmd_ge 2.088 && LTO="ENABLE_LTO=1"
	# 2.080 and below used RELEASE instead of ENABLE_RELEASE
	dmd_ge 2.081 && ENABLE_RELEASE="ENABLE_RELEASE" || ENABLE_RELEASE="RELEASE"

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
		export DMD="${kernel}/bin${model}/dmd"
		if ! dmd_ge 2.094; then
			export DMD="../../${DMD}"
		fi
	fi
	if dmd_ge 2.094; then
		einfo "Building dmd build script..."
		dlang_compile_bin dmd/generated/build dmd/src/build.d
		einfo "Building dmd..."
		env VERBOSE=1 ${HOST_DMD}="${DMD}" CXX="$(tc-getCXX)" ${ENABLE_RELEASE}=1 ${LTO} dmd/generated/build DFLAGS="$(dlang_dmdw_dcflags)" dmd
	else
		einfo "Building dmd..."
		emake -C dmd/src -f posix.mak TARGET_CPU=X86 ${HOST_DMD}="${DMD}" ${HOST_CXX}="$(tc-getCXX)" ${ENABLE_RELEASE}=1 ${LTO}
	fi

	# Don't pick up /etc/dmd.conf when calling $(dmd_gen_exe_dir)/dmd !
	if [ ! -f "$(dmd_gen_exe_dir)/dmd.conf" ]; then
		einfo "Creating a dummy dmd.conf"
		touch "$(dmd_gen_exe_dir)/dmd.conf" || die "Could not create dummy dmd.conf"
	fi

	compile_libraries() {
		einfo 'Building druntime...'
		emake -C druntime -f posix.mak DMD="../$(dmd_gen_exe_dir)/dmd" MODEL=${MODEL} PIC=1 MANIFEST=

		einfo 'Building Phobos 2...'
		emake -C phobos -f posix.mak DMD="../$(dmd_gen_exe_dir)/dmd" MODEL=${MODEL} PIC=1 CUSTOM_DRUNTIME=1
	}

	dmd_foreach_abi compile_libraries

	# Not needed after compilation. Would otherwise be installed as imports.
	rm -r phobos/etc/c/zlib
}

dmd_src_test() {
	test_hello_world() {
		"$(dmd_gen_exe_dir)/dmd" -m${MODEL} -fPIC -Iphobos -Idruntime/import -L-Lphobos/generated/linux/release/${MODEL} samples/d/hello.d || die "Failed to build hello.d (${MODEL}-bit)"
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
DFLAGS=%DFLAGS% -L-L/${PREFIX}/lib32 -L-rpath=/${PREFIX}/lib32
[Environment64]
DFLAGS=%DFLAGS% -L-L/${PREFIX}/lib64 -L-rpath=/${PREFIX}/lib64
EOF
	elif [ "${ABI:0:5}" = "amd64" ]; then
		cat > linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2 -fPIC -L-L/${PREFIX}/lib64 -L-rpath=/${PREFIX}/lib64
EOF
	else
		cat > linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2 -fPIC -L-L/${PREFIX}/lib -L-rpath=/${PREFIX}/lib
EOF
	fi
	insinto "etc/dmd"
	newins "linux/bin${MODEL}/dmd.conf" "${SLOT}.conf"
	dosym "../../../../../etc/dmd/${SLOT}.conf" "${PREFIX}/bin/dmd.conf"

	# DMD
	einfo "Installing ${PN}..."
	# From version 2.066 on, dmd will find dmd.conf in the executable directory, if we
	# call it through a symlink in /usr/bin
	dmd_ge 2.066 && dosym "../../${PREFIX}/bin/dmd" "${ROOT}/usr/bin/dmd-${SLOT}"
	into ${PREFIX}
	dobin "$(dmd_gen_exe_dir)/dmd"

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
			local libdir="../${PREFIX}/lib${MODEL}"
		else
			local libdir="../${PREFIX}/lib"
		fi

		# Install shared lib.
		dolib.so phobos/generated/linux/release/${MODEL}/"${SONAME}"
		dosym "${SONAME}" /usr/"$(get_libdir)"/"${SONAME_SYM}"
		dosym ../../../../../usr/"$(get_libdir)"/"${SONAME}" /usr/"${libdir}"/libphobos2.so

		# Install static lib if requested.
		if use static-libs; then
			if has_multilib_profile || [[ "${MODEL}" == "64" ]]; then
				export LIBDIR_${ABI}="../${PREFIX}/lib${MODEL}"
			else
				export LIBDIR_${ABI}="../${PREFIX}/lib"
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

dmd_foreach_abi() {
	for ABI in $(multilib_get_enabled_abis); do
		local MODEL=$(dmd_abi_to_model)
		einfo "  Executing ${1} in ${MODEL}-bit ..."
		"${@}"
	done
}

dmd_arch_to_model() {
	[[ "${ARCH}" == "amd64" ]] && echo 64 || echo 32
}

dmd_abi_to_model() {
	[[ "${ABI:0:5}" == "amd64" ]] && echo 64 || echo 32
}

fi
