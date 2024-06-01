# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Package and build management system for D"
HOMEPAGE="https://code.dlang.org/"

DUB_TEST_DEPS=(
	gitcompatibledubpackage@1.0.1
	gitcompatibledubpackage@1.0.4
	urld@2.1.1
)
generate_dub_test_dependencies() {
	local dep
	for dep in "${DUB_TEST_DEPS[@]}"; do
		local depName depVersion
		depName="${dep%@*}"
		depVersion="${dep#*@}"
		echo "https://code.dlang.org/packages/${depName}/${depVersion}.zip -> ${depName}-${depVersion}.zip"
	done
}

GITHUB_URI="https://codeload.github.com/dlang"
SRC_URI="
	${GITHUB_URI}/${PN}/tar.gz/v${PV} -> ${PN}-${PV}.tar.gz
	test? (
		$(generate_dub_test_dependencies)
	)
"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

IUSE="doc test"
RESTRICT="!test? ( test )"

DLANG_COMPAT=( dmd-2_{106..108} gdc-13 ldc2-1_{35..38} )

inherit dlang-single shell-completion

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}

src_unpack() {
	unpack "${P}.tar.gz"

	if use test; then
		# Copy the archives locally. Some tests do need to perform an
		# actual fetch operation so make all of them available as
		# archives and let dub figure out the rest.
		local store="${T}/dub-test-deps"
		mkdir -p "${store}" || die

		local dep
		for dep in "${DUB_TEST_DEPS[@]}"; do
			local depName depVersion
			depName="${dep%@*}"
			depVersion="${dep#*@}"

			cp "${DISTDIR}/${depName}-${depVersion}.zip" "${store}" || die
		done

		# Generate a settings.json file that points to the directory with all the deps.
		# Note that "skipRegistry" doesn't seem to be respected.
		cat <<EOF > "${T}/settings.json"
{
	"registryUrls": [
		"file://${store}"
	],
	"skipRegistry": "standard"
}
EOF
	fi
}

src_compile() {
	# gdc generates unaligned memory accesses with optimizations and avx
	# enabled. It has been fixed upstream. See:
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=114171
	# Fixed in >=sys-devel/gcc-13.2.1_p20240330. Adding -mno-sse2 makes
	# tests fail so defer to removing the common way users get avx
	# instructions enabled (-march=native) and warn them.
	if [[ ${ARCH} == amd64 && ${EDC} == gdc* && ${DCFLAGS} == *-march=native* ]]; then
		ewarn "<sys-devel/gcc-13.2.1_p20240330 is known to generate invalid code"
		ewarn "on amd64 with certain flags. For this reason -march=native will be"
		ewarn "removed from your flags. Feel free to use -march=<cpu> to bypass this"
		ewarn "precaution."
		ewarn ""
		ewarn "See also: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=114171"
		dlang-filter-dflags "gdc*" "-march=native"
	fi

	local imports=source versions="DubApplication DubUseCurl"
	dlang_compile_bin bin/dub $(<build-files.txt)

	# Generate man pages. Rebuids dub so put it behind a USE flag.
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
	local -x DUB_HOME="${T}/dub-home" # where to put artifacts

	# Note, disabling tests is possible yet very hard. You have to
	# create a bash variable containing a regex (to be used in =~) that
	# matches all the tests that you want *to* run. It's probably easier
	# to delete the subdirectory under ${S}/test.

	# Tries to connect to github.com and fails due to the network sandbox
	rm -rf "${S}/test/git-dependency" || die
	# Doesn't work on non amd64/x86
	if [[ ${ARCH} == arm64 ]]; then
		rm -rf test/issue1447-build-settings-vars || die
	fi

	local dropImportCTest
	# We have an importC test and not all compilers pass it properly.
	# gdc doesn't support #include's in its importC implementation yet.
	# Only check == 13 since 12 is skipped by the script.
	[[ ${EDC} == gdc* ]] && [[ $(dlang_get_be_version) == 13 ]] && dropImportCTest=1
	# Nor does <=ldc2-1.32.
	[[ ${EDC} == ldc* ]] && $(ver_test $(dlang_get_be_version) -le 1.32) && dropImportCTest=1
	# dmd can do #include's but there are some other errors about
	# __float128 in <=dmd-2.102 on x86.
	[[ ${EDC} == dmd* ]] && $(ver_test $(dlang_get_be_version) -le 2.102) \
		&& [[ ${ARCH} == x86 ]] && dropImportCTest=1
	if [[ ${dropImportCTest} ]]; then
		rm -rf "${S}/test/use-c-sources" || die
	fi

	# Put the configuration file relative to the dub binary:
	# <dub-bin-dir>/../etc/dub/settings.json as per
	# https://dub.pm/dub-reference/settings so that it's picked up
	# automatically.
	mkdir -p "${S}/bin/../etc/dub" || die
	cp "${T}/settings.json" "${S}/bin/../etc/dub/" \
		|| die "Could not copy dub configuration file"

	# See https://bugs.gentoo.org/921581 we have to remove -op (preserve
	# source path for output files) from the flags lest the sandbox
	# trips us up. This shouldn't be a problem anymore with dlang-single.
	dlang-filter-dflags "*" "--op" "-op"

	# Append -Wno-error or equivalent
	DCFLAGS+=" $(dlang_get_wno_error_flag)"

	# Run the unittests in the source files.
	# "skipRegistry" from settings.json isn't respected. Nothing breaks
	# but the info messages are clearer (they don't include references to URLs).
	DFLAGS="${DCFLAGS}" "${DUB}" --skip-registry=all test -v -c application

	# Run the integration tests.
	DFLAGS="${DCFLAGS}" FRONTEND="$(dlang_get_fe_version)" test/run-unittest.sh  \
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
