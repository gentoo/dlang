# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Auto-complete program for the D programming language"
HOMEPAGE="https://github.com/dlang-community/DCD"

MY_PV=$(ver_rs 3 - 4 .) # For beta releases 0.16.0_beta2 -> 0.16.0-beta.2

CONTAINERS="116a02872039efbd0289828cd5eeff6f60bdf539"
LIBDPARSE="f8a6c28589aae180532fb460a1b22e92a0978292"
MSGPACK="26ef07e16023483ad93e3f86374b19d0e541c924"
SRC_URI="
	https://github.com/dlang-community/DCD/archive/v${MY_PV}.tar.gz -> DCD-${MY_PV}.tar.gz
	https://github.com/economicmodeling/containers/archive/${CONTAINERS}.tar.gz -> containers-${CONTAINERS}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	https://github.com/msgpack/msgpack-d/archive/${MSGPACK}.tar.gz -> msgpack-d-${MSGPACK}.tar.gz
	"
S="${WORKDIR}/DCD-${MY_PV}"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="systemd"

PATCHES=(
	"${FILESDIR}/pr-774.patch"
)

DLANG_COMPAT=( dmd-2_{106..111} gdc-1{3..5} ldc2-1_{35..40} )

inherit dlang-single systemd bash-completion-r1

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}

src_prepare() {
	# Default ebuild unpack function places archives side-by-side ...
	mv -T ../containers-${CONTAINERS}    containers            || die
	mv -T ../libdparse-${LIBDPARSE}      libdparse             || die
	mv -T ../msgpack-d-${MSGPACK}        msgpack-d             || die
	# Stop the makefile from executing git to write an unused githash.txt
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
	cd tests && ./run_tests.sh --extra || die "Tests failed"
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
