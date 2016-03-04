# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Reference compiler for the D programming language"
HOMEPAGE="http://dlang.org"

# License doesn't allow redistribution
LICENSE="DMD"
RESTRICT="mirror"

# DMD supports amd64/x86 exclusively
MULTILIB_COMPAT=( abi_x86_{32,64} )
KEYWORDS="-* ~amd64 ~x86"
IUSE="doc examples tools"

DLANG_VERSION_RANGE="2.067-"
DLANG_PACKAGE_TYPE="single"

inherit eutils dlang versionator multilib-build

SLOT="$(get_version_component_range 1-2)"
MAJOR="$(get_major_version)"
MINOR="$((10#$(get_version_component_range 2)))"
PATCH="$(get_version_component_range 3)"
VERSION="$(get_version_component_range 1-3)"
BETA="$(echo $(get_version_component_range 4) | cut -c 5-)"

if [[ -n "${BETA}" ]]; then
	SRC_URI="http://downloads.dlang.org/pre-releases/${MAJOR}.x/${VERSION}/${PN}.${VERSION}-b${BETA}.linux.tar.xz"
else
	SRC_URI="mirror://aws/2016/${PN}.${PV}.zip"
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

src_prepare() {
	# Remove precompiled binaries and non-essential files
	rm -r README.TXT windows osx freebsd linux || die "Failed to remove included binaries."

	# Convert line-endings of file-types that start as cr-lf and are installed later on
	for file in $( find . -name "*.txt" -o -name "*.html" -o -name "*.d" -o -name "*.di" -o -name "*.ddoc" -type f ); do
		edos2unix $file || die "Failed to convert DOS line-endings to Unix."
	done

	# Fix the messy directory layout so the three make files can cooperate
	mv src/druntime druntime || die
	mv src/phobos phobos || die
	mv src dmd || die
	mv dmd/dmd dmd/src || die

	# User patches
	epatch_user
}

abi_to_model() {
	[[ "${ABI:0:5}" == "amd64" ]] && echo 64 || echo 32
}

dmd_foreach_abi() {
	for ABI in $(multilib_get_enabled_abis); do
		local MODEL=$(abi_to_model)
		einfo "Executing ${1} in ${MODEL}-bit ..."
		"${@}"
	done
}

src_compile() {
	#Need to set PIC if GCC is hardened, otherwise users will be unable to link Phobos
	if [[ $(gcc --version | grep -o Hardened) ]]; then
		einfo "Hardened GCC detected - setting PIC"
		PIC="PIC=1"
	fi

	# A native build of dmd is used to compile the runtimes for both x86 and amd64
	# We cannot use multilib-minimal yet, as we have to be sure dmd for amd64
	# always gets build first.
	einfo "Building ${PN}..."
	emake -C dmd/src -f posix.mak TARGET_CPU=X86 HOST_DMD="${DMD}" RELEASE=1

	compile_libraries() {
		einfo 'Building druntime...'
		emake -C druntime -f posix.mak MODEL=${MODEL} ${PIC}

		einfo 'Building Phobos 2...'
		emake -C phobos -f posix.mak MODEL=${MODEL} ${PIC}
	}

	dmd_foreach_abi compile_libraries
}

src_test() {
	test_hello_world() {
		dmd/src/dmd -m${MODEL} -Iphobos -Idruntime/import -L-Lphobos/generated/linux/release/${MODEL} samples/d/hello.d || die "Failed to build hello.d (${MODEL}-bit)"
		./hello ${MODEL}-bit || die "Failed to run test sample (${MODEL}-bit)"
		rm hello.o hello || die
	}

	dmd_foreach_abi test_hello_world
}

src_install() {
	local MODEL=$(abi_to_model)

	# Prepeare dmd.conf
	mkdir -p dmd/ini/linux/bin${MODEL} || die "Failed to create directory: dmd/ini/linux/bin${MODEL}"
	if has_multilib_profile; then
		cat > dmd/ini/linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2
[Environment32]
DFLAGS=%DFLAGS% -L-L/${PREFIX}/lib32 -L-rpath -L/${PREFIX}/lib32
[Environment64]
DFLAGS=%DFLAGS% -L-L/${PREFIX}/lib64 -L-rpath -L/${PREFIX}/lib64
EOF
	else
		cat > dmd/ini/linux/bin${MODEL}/dmd.conf << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L--export-dynamic -defaultlib=phobos2 -L-L/${PREFIX}/lib${MODEL} -L-rpath -L/${PREFIX}/lib${MODEL}
EOF
	fi

	# DMD
	einfo "Installing ${PN}..."
	emake -C dmd/src -f posix.mak TARGET_CPU=X86 RELEASE=1 install
	into ${PREFIX}
	dobin install/linux/bin${MODEL}/dmd
	insinto ${PREFIX}/bin
	doins install/linux/bin${MODEL}/dmd.conf
	insinto ${PREFIX}
	doins install/{dmd-boostlicense,dmd-backendlicense}.txt
	dosym "/${PREFIX}/bin/dmd" "${ROOT}/usr/bin/dmd-${SLOT}"

	einfo 'Installing druntime...'
	install_druntime() {
		emake -C druntime -f posix.mak LIB_DIR="$(get_libdir)" MODEL=${MODEL} install
	}
	dmd_foreach_abi install_druntime
	doins -r install/src/druntime/import
	doins install/druntime-LICENSE.txt

	einfo 'Installing Phobos 2...'
	install_library() {
		emake -C phobos -f posix.mak LIB_DIR="$(get_libdir)" MODEL=${MODEL} install
		dolib.a install/linux/lib${MODEL}/libphobos2.a
		dolib.so install/linux/lib${MODEL}/libphobos2.so.0.${MINOR}.${PATCH}
		dolib.so install/linux/lib${MODEL}/libphobos2.so
		dosym libphobos2.so.0.${MINOR}.${PATCH} ${PREFIX}/$(get_libdir)/libphobos2.so.0.${MINOR}
	}
	dmd_foreach_abi install_library
	insinto ${PREFIX}/import
	doins -r install/src/phobos/*
	insinto ${PREFIX}
	doins install/phobos-LICENSE.txt

	# man pages, docs and samples
	insinto ${PREFIX}/man/man1
	doins man/man1/dmd.1
	insinto ${PREFIX}/man/man5
	doins man/man5/dmd.conf.5
	insinto ${PREFIX}
	use doc && doins -r html
	if use examples; then
		docompress -x ${PREFIX}/samples/
		insinto ${PREFIX}/samples
		doins -r samples/d/*
	fi
}

pkg_postinst() {
	# Update active dmd
	"${ROOT}"/usr/bin/eselect dlang update dmd

	elog "License files are in: /${PREFIX}"
	use examples && elog "Examples can be found in: /${PREFIX}/samples"
	use doc && elog "HTML documentation is in: /${PREFIX}/html"
}

pkg_postrm() {
	"${ROOT}"/usr/bin/eselect dlang update dmd
}
