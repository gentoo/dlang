# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Auto-complete program for the D programming language"
HOMEPAGE="https://github.com/dlang-community/DCD"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="systemd"

CONTAINERS="116a02872039efbd0289828cd5eeff6f60bdf539"
DTESTUTILS="206a2e6abd97b4462f3a320e4f2d23986fad3cff"
LIBDPARSE="592ef39a73a58439afc75a3e6c13a0d87d0b847d"
MSGPACK="480f3bf9ee80ccf6695ed900cfcc1850ba8da991"
SRC_URI="
	https://github.com/dlang-community/DCD/archive/v${PV}.tar.gz -> DCD-${PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/dlang-community/d-test-utils/archive/${DTESTUTILS}.tar.gz -> d-test-utils-${DTESTUTILS}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"
S="${WORKDIR}/DCD-${PV}"

DLANG_COMPAT=( dmd-2_{106..107} gdc-13 ldc2-1_{35..36} )

inherit dlang-single systemd bash-completion-r1

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../containers-${CONTAINERS}    containers            || die
	mv -T ../d-test-utils-${DTESTUTILS}  d-test-utils          || die
	mv -T ../libdparse-${LIBDPARSE}      libdparse             || die
	mv -T ../msgpack-d-${MSGPACK}        msgpack-d             || die
	# Stop makefile from executing git to write an unused githash.txt
	mkdir bin || die "Coult not create output directory"
	echo "v${PV}" > bin/githash.txt || die "Could not generate githash"
	touch githash || die "Could not generate githash"

	# Apply patches
	default
}

src_compile() {
	# Don't let the makefile overwrite user flags.
	# The downside is that we have to also pass the include dirs.
	local flags="${DCFLAGS} ${DLANG_LDFLAGS}"
	flags+=" -Icontainers/src -Idsymbol/src -Ilibdparse/src -Imsgpack-d/src -Isrc -Jbin"
	# An uppercase name of the compiler. It can be GDC, LDC or DMD
	local name=${EDC::3}
	name=${name^^}

	# Build client & server with the requested Dlang compiler.
	local mymakeargs=(
		# The path to the correct compiler
		"${name}=${DC}"
		# The flags for the client and the server
		"${name}_CLIENT_FLAGS=${flags} $(dlang_get_output_flag)bin/dcd-client"
		"${name}_SERVER_FLAGS=${flags} $(dlang_get_output_flag)bin/dcd-server"
		# The target to build, the lowercase version of the compiler name
		${name,,}
	)
	emake "${mymakeargs[@]}"

	# Write system include paths of host implementation into dcd.conf
	dlang_print_system_import_paths > dcd.conf
}

src_test() {
	# Note, the makefile compiles the server with -g for tests.
	cd tests && ./run_tests.sh || die "Tests failed"
}

src_install() {
	dobin bin/dcd-server
	dobin bin/dcd-client
	use systemd && systemd_douserunit "${FILESDIR}"/dcd-server.service
	dobashcomp bash-completion/completions/dcd-server
	dobashcomp bash-completion/completions/dcd-client
	insinto /etc
	doins dcd.conf
	dodoc README.md
	doman man1/dcd-client.1 man1/dcd-server.1
}

pkg_postinst() {
	use systemd && elog "A systemd user service for 'dcd-server' has been installed."
}
