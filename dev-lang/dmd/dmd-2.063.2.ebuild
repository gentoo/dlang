# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils multilib-build

DESCRIPTION="Reference compiler for the D programming language"
HOMEPAGE="http://dlang.org/"
SRC_URI="http://downloads.dlang.org.s3.amazonaws.com/releases/2013/${PN}.${PV}.zip"

# DMD supports amd64/x86 exclusively
KEYWORDS="amd64 x86"
SLOT="2.063"
IUSE="doc examples"

# License doesn't allow redistribution
LICENSE="DMD"
RESTRICT="mirror"

DEPEND="
	app-arch/unzip
	app-admin/eselect-dlang
	"
RDEPEND="!dev-lang/dmd-bin"

S="${WORKDIR}/dmd2"

PREFIX="opt/${PN}-${SLOT}"
IMPORT_DIR="/${PREFIX}/import"

src_prepare() {
	# Remove precompiled binaries and non-essential files.
	rm -r README.TXT windows osx linux || die "Failed to remove included binaries."

	# convert line-endings of file-types that start as cr-lf and are patched or installed later on
	for file in $( find . -name "*.txt" -o -name "*.html" -o -name "*.d" -o -name "*.di" -o -name "*.ddoc" -type f ); do
		edos2unix $file || die "Failed to convert DOS line-endings to Unix."
	done

	# patch: copy VERSION file into dmd directory
	cp src/VERSION src/dmd/VERSION || die "Failed to copy VERSION file into dmd directory."

	# Rename man pages to reflect slot number.
	mkdir man/man5 || die "Failed to create man/man5."
	mv man/man1/dmd.conf.5 man/man5/dmd.conf.5

	# Write a simple dmd.conf to bootstrap druntime and phobos
	cat > src/dmd/dmd.conf << EOF
[Environment]
DFLAGS=-L--export-dynamic
EOF

	# Copy missing LICENSE_1_0.txt
	cp "${FILESDIR}/LICENSE_1_0.txt" src/phobos/ || die "Couldn't copy LICENSE_1_0.txt"
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
	# A native build of dmd is used to compile the runtimes for both x86 and amd64
	# We cannot use multilib-minimal yet, as we have to be sure dmd for amd64
	# always gets build first.
	einfo "Building ${PN}..."
	emake -C src/dmd -f posix.mak TARGET_CPU=X86 RELEASE=1

	compile_libraries() {
		einfo 'Building druntime...'
		emake -C src/druntime -f posix.mak MODEL=${MODEL} DMD=../dmd/dmd

		einfo 'Building Phobos 2...'
		emake -C src/phobos -f posix.mak MODEL=${MODEL} DMD=../dmd/dmd
	}

	dmd_foreach_abi compile_libraries
}

src_test() {
	test_hello_world() {
		src/dmd/dmd -m${MODEL} -Isrc/phobos -Isrc/druntime/import -L-Lsrc/phobos/generated/linux/release/${MODEL} samples/d/hello.d || die "Failed to build hello.d (${MODEL}-bit)"
		./hello ${MODEL}-bit || die "Failed to run test sample (${MODEL}-bit)"
		rm hello.o hello
	}

	dmd_foreach_abi test_hello_world
}

src_install() {
	# Prepeare and install config file.
	if has_multilib_profile; then
		cat > src/dmd/dmd.conf.default << EOF
[Environment32]
DFLAGS=-I${IMPORT_DIR} -L-L/${PREFIX}/lib32 -L-rpath -L/${PREFIX}/lib32 -L--export-dynamic
[Environment64]
DFLAGS=-I${IMPORT_DIR} -L-L/${PREFIX}/lib64 -L-rpath -L/${PREFIX}/lib64 -L--export-dynamic
EOF
	else
		cat > src/dmd/dmd.conf.default << EOF
[Environment]
DFLAGS=-I${IMPORT_DIR} -L-L/${PREFIX}/lib -L-rpath -L/${PREFIX}/lib -L--export-dynamic
EOF
	fi
	einfo "Installing ${PN}..."
	into ${PREFIX}
	dobin src/dmd/dmd
	insinto ${PREFIX}/bin
	newins src/dmd/dmd.conf.default dmd.conf
	insinto ${PREFIX}
	newins src/dmd/backendlicense.txt dmd-backendlicense.txt
	newins src/dmd/artistic.txt dmd-artistic.txt

	einfo 'Installing druntime...'
	install_druntime() {
		into ${PREFIX}
		dolib.a src/druntime/lib/libdruntime-linux${MODEL}.a
		dolib.a src/druntime/lib/libdruntime-linux${MODEL}so.a
		dolib src/druntime/lib/libdruntime-linux${MODEL}so.o
	}
	dmd_foreach_abi install_druntime
	newins src/druntime/LICENSE druntime-LICENSE.txt
	insinto ${PREFIX}/import
	doins -r src/druntime/import/*

	einfo 'Installing Phobos 2...'
	install_library() {
		into ${PREFIX}
		dolib.a src/phobos/generated/linux/release/${MODEL}/libphobos2.a
		dolib.so src/phobos/generated/linux/release/${MODEL}/libphobos2.so.0.2.0
		dosym libphobos2.so.0.2.0 ${PREFIX}/$(get_libdir)/libphobos2.so.0.2
		dosym libphobos2.so.0.2.0 ${PREFIX}/$(get_libdir)/libphobos2.so
	}
	dmd_foreach_abi install_library
	insinto ${PREFIX}/import
	doins -r src/phobos/std
	doins -r src/phobos/etc
	doins src/phobos/crc32.d
	insinto ${PREFIX}
	newins src/phobos/LICENSE_1_0.txt phobos-LICENSE.txt

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
	elog "License files are in: /${PREFIX}"
	use examples && elog "Examples can be found in: /${PREFIX}/samples"
	use doc && elog "HTML documentation is in: /${PREFIX}/html"
}
