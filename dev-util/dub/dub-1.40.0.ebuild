# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( dmd-2_{106..111} gdc-1{3..5} ldc2-1_{35..40} )
DUB_DEPENDENCIES=(
	gitcompatibledubpackage@1.0.1
	gitcompatibledubpackage@1.0.4
	urld@2.1.1
)
inherit dlang-single dub shell-completion

DESCRIPTION="Package and build management system for D"
HOMEPAGE="https://code.dlang.org/"

GITHUB_URI="https://codeload.github.com/dlang"
man_pages_uri="https://github.com/the-horo/distfiles/releases/download/init"
SRC_URI="
	${GITHUB_URI}/${PN}/tar.gz/v${PV} -> ${P}.tar.gz
	${man_pages_uri}/${P}-man-pages.tar.gz
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
	unpack "${P}.tar.gz" "${P}-man-pages.tar.gz"
	use test && dub_copy_dependencies_locally "${DUB_DEPENDENCIES[@]}"
}

src_prepare() {
	# Note, disabling tests is possible yet very hard. You have to
	# create a bash variable containing a regex (to be used in =~) that
	# matches all the tests that you want *to* run. It's probably easier
	# to delete the subdirectory under ${S}/test.

	# Tries to connect to github.com and fails due to the network sandbox
	rm -r "${S}/test/git-dependency" || die

	# gdc doesn't support #include's in its importC implementation.
	if [[ ${EDC} == gdc* ]]; then
		rm -r "${S}/test/use-c-sources" || die
		rm -r "${S}/test/issue2698-cimportpaths-broken-with-dmd-ldc" || die
	fi

	# $(basename DC) not matching ^(dmd|ldc2|gdc)$ makes the test runner
	# not skip known failures, so skip them here instead
	if [[ ${EDC} == dmd* ]]; then
		rm -r test/issue2258-dynLib-exe-dep || die
	fi
	if [[ ${EDC} != ldc2* ]]; then
		rm -r test/depen-build-settings || die
	fi

	default
}

src_compile() {
	# dmd misscompilation with -O
	# https://github.com/dlang/dmd/issues/21400
	dlang-filter-dflags dmd* -O*

	local imports=source versions="DubApplication DubUseCurl"
	dlang_compile_bin bin/dub $(<build-files.txt)
}

src_test() {
	# Setup the environment for the tests.
	local -x DUB="${S}/bin/dub"

	# Specifying DFLAGS in the environment disables unittests. Outside
	# of a better solution, put them in a wrapper file
	local dflags=( ${DCFLAGS} ${DLANG_LDFLAGS} $(dlang_get_wno_error_flag) )

	[[ ${EDC} == gdc* ]] && dflags+=( -fall-instantiations )

	# -g causes ICE, only on tests
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=119817
	[[ ${EDC} =~ gdc-1(3|4) ]] && dflags+=( -g0 )

	mkdir -p "${T}/${PN}"

	local wdc="${T}/${PN}/${EDC}"
	cat > "${wdc}" <<-EOF || die
	#!${BROOT}/bin/sh
	${DC} "\${@}" ${dflags[*]}
	EOF
	chmod +x "${wdc}"
	local -x DC="${wdc}"

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

	doman "${WORKDIR}/${P}-man-pages"/*

	newbashcomp scripts/bash-completion/${PN}.bash ${PN}
	dozshcomp scripts/zsh-completion/_${PN}
	dofishcomp scripts/fish-completion/${PN}.fish
}
