# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( dmd-2_{106..109} gdc-1{3,4} ldc2-1_{35..39} )
DUB_DEPENDENCIES=(
	gitcompatibledubpackage@1.0.1
	gitcompatibledubpackage@1.0.4
	urld@2.1.1
)
inherit dlang-single dub shell-completion

DESCRIPTION="Package and build management system for D"
HOMEPAGE="https://code.dlang.org/"

GITHUB_URI="https://codeload.github.com/dlang"
SRC_URI="
	${GITHUB_URI}/${PN}/tar.gz/v${PV} -> ${P}.tar.gz
	test? ( ${DUB_DEPENDENCIES_URIS} )
"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="doc test"
RESTRICT="!test? ( test )"

RDEPEND+=" virtual/pkgconfig"

src_unpack() {
	dub_gen_settings
	unpack "${P}.tar.gz"
	use test && dub_copy_dependencies_locally "${DUB_DEPENDENCIES[@]}"
}

src_configure() {
	# gdc generates unaligned memory accesses with optimizations and avx
	# enabled. It has been fixed upstream. See:
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=114171
	# Fixed in >=sys-devel/gcc-13.2.1_p20240330. Adding -mno-sse2 makes
	# tests fail so defer to removing the common way users get avx
	# instructions enabled (-march=native) and warn them.
	if [[ ${ARCH} == amd64 && ${EDC} == gdc-13 && ${DCFLAGS} == *-march=native* ]]; then
		ewarn "<sys-devel/gcc-13.2.1_p20240330 is known to generate invalid code"
		ewarn "on amd64 with certain flags. For this reason -march=native will be"
		ewarn "removed from your flags. Feel free to use -march=<cpu> to bypass this"
		ewarn "precaution."
		ewarn ""
		ewarn "See also: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=114171"
		dlang-filter-dflags "gdc*" "-march=native"
	fi
}

src_compile() {
	local imports=source versions="DubApplication DubUseCurl"
	dlang_compile_bin bin/dub $(<build-files.txt)

	# Generate man pages. Rebuilds dub so put it behind a USE flag.
	if use doc; then
		einfo "Generating man pages"
		# You're supposed to be able to do ./bin/dub scrips/man/gen_man.d
		# but it gives linking errors with gdc.

		# $imports is set up above.
		versions=DubUseCurl
		dlang_compile_bin scripts/man/gen_man{,.d} \
						  $(sed '/^source\/app.d$/d' build-files.txt)
		./scripts/man/gen_man || die "Could not generate man pages"
	fi
}

src_test() {
	# Setup the environment for the tests.
	local -x DUB="${S}/bin/dub"

	# Note, disabling tests is possible yet very hard. You have to
	# create a bash variable containing a regex (to be used in =~) that
	# matches all the tests that you want *to* run. It's probably easier
	# to delete the subdirectory under ${S}/test.

	# Tries to connect to github.com and fails due to the network sandbox
	rm -rf "${S}/test/git-dependency" || die
	# Doesn't work on non amd64/x86
	if [[ ${ARCH} != @(amd64|x86) ]]; then
		rm -rf test/issue1447-build-settings-vars || die
	fi

	# gdc-13 doesn't support #include's in its importC implementation.
	if [[ ${EDC} == gdc-13 ]]; then
		rm -rf "${S}/test/use-c-sources" || die
	fi

	# See https://bugs.gentoo.org/921581 we have to remove -op (preserve
	# source path for output files) from the flags lest the sandbox
	# trips us up. This shouldn't be a problem anymore with dlang-single.
	dlang-filter-dflags "*" "--op" "-op"

	# Use -Wno-error or equivalent
	local -x DFLAGS="${DCFLAGS} ${DLANG_LDFLAGS} $(dlang_get_wno_error_flag)"

	# Run the unittests in the source files.
	"${DUB}" test --verbose -c application || die

	# Some tests overwrite DUB_HOME messing up the configuration file
	# so put it in one of the other available locations
	mkdir -p "${S}/bin/../etc/dub" || die
	cp "${DUB_HOME}/settings.json" "${S}/bin/../etc/dub/settings.json" || die

	# Run the integration tests.
	FRONTEND="$(dlang_get_fe_version)" test/run-unittest.sh  \
		|| die "Tests failed"
}

src_install() {
	dobin bin/dub
	dodoc README.md

	# Make sure there are no man files in any other section.
	use doc && doman scripts/man/*.1

	newbashcomp scripts/bash-completion/${PN}.bash ${PN}
	dozshcomp scripts/zsh-completion/_${PN}
	dofishcomp scripts/fish-completion/${PN}.fish
}
