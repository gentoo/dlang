# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Package and build management system for D"
HOMEPAGE="https://code.dlang.org/"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="debug test"
RESTRICT="!test? ( test )"

DUB_TEST_DEPS=(
	gitcompatibledubpackage@1.0.1
	gitcompatibledubpackage@1.0.4
	urld@2.1.1
)
generate_dub_dependencies() {
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
	$(generate_dub_dependencies)
)
"

# Upstream recommends the latest version available
DLANG_VERSION_RANGE="2.100-2.106"
DLANG_PACKAGE_TYPE="single"

inherit dlang

src_unpack() {
	unpack "${PN}-${PV}.tar.gz"

	if use test; then
		# Copy the archives locally. Some tests do need to perform an
		# actual fetch operation so make all of them available as
		# archives and let dub figure out the rest.
		local dep
		for dep in "${DUB_TEST_DEPS[@]}"; do
			local depName depVersion
			depName="${dep%@*}"
			depVersion="${dep#*@}"

			cp "${DISTDIR}/${depName}-${depVersion}.zip" "${T}" || die
		done

		# Generate a dub.settings.json file that points to the directory with all the deps
		cat <<EOF > "${T}/dub.settings.json"
{
	"registryUrls": [
		"file://${T}"
	],
	"skipRegistry": "all"
}
EOF
	fi
}

d_src_compile() {
	local imports=source versions="DubApplication DubUseCurl"
	dlang_compile_bin bin/dub $(<build-files.txt)

	## Currently broken with gdc
	# Generate man pages
	#bin/dub scripts/man/gen_man.d || die "Could not generate man pages."
}

d_src_test() {
	# Ideally don't export $DUB to not mess up the scripts (if any) in src_install.
	local DUB="${S}/bin/dub"
	# Note, disabling tests is possible yet very hard. You have to create a bash variable containing a
	# regex (to be used in =~) that matches all the tests that you want *to* run. It's probably easier to
	# delete the subdirectory under ${S}/test.

	# Tries to connect to github.com and fails due to the network sandbox
	rm -rf "${S}/test/git-dependency" || die
	# Doesn't work on non amd64/x86
	if [[ ${ARCH} != amd64 ]] && [[ ${ARCH} != x86 ]]; then
		rm -rf test/issue1447-build-settings-vars
	fi

	if [[ ${DLANG_VENDOR} == GNU ]]; then
		# Doesn't work with gdc. It doesn't like gdc being in the form ${CHOST}-gdc.
		# In the source the test is skipped for dmd and gdc.
		rm -rf test/depen-build-settings || die

		# Some tests fail because gdc enables dip1000 by default which
		# adds a bunch of deprecations. Since deprecations are warnings
		# for gdc and dub adds -Werror by default we have to turn it
		# off. Since we can't turn it off yet we have to delete the
		# test.  See: https://github.com/dlang/dub/pull/2796
		rm -rf test/dub-as-a-library-cwd || die
	fi

	local dropImportCTest
	# We have an importC test and not all compilers pass it properly.
	# gdc-13 doesn't support #include's in its importC implementation yet.
	[[ ${DLANG_VENDOR} == GNU ]] && [[ ${DC_VERSION} -ge 13 ]] && dropImportCTest=1
	# Nor does <=ldc2-1.32.
	[[ ${DLANG_VENDOR} == LDC ]] && $(ver_test ${DC_VERSION} -le 1.32) && dropImportCTest=1
	# dmd can do #include's but there are some other errors about __float128 in <=dmd-2.102 for non amd64.
	[[ ${DLANG_VENDOR} == DigitalMars ]] && $(ver_test ${DC_VERSION} -le 2.102) \
		&& [[ ${ARCH} != amd64 ]] && dropImportCTest=1
	if [[ -n ${dropImportCTest} ]]; then
		rm -rf "${S}/test/use-c-sources" || die
	fi

	# Put the configuration file relative to the dub binary:
	# <dub-bin-dir>/../etc/dub/settings.json as per
	# https://dub.pm/dub-reference/settings so that it's picked up
	# automatically.
	mkdir -p "${S}/bin/../etc/dub" || die
	cp "${T}/dub.settings.json" "${S}/bin/../etc/dub/settings.json" \
		|| die "Could not copy dub configuration file"

	# See https://bugs.gentoo.org/921581 we have to remove -op (preserve source path for output files)
	# from the flags lest the sandbox trips us up.
	local filteredDflags="${DCFLAGS//--op/}"
	filteredDflags="${filteredDflags//-op/}"

	# There's no easy way to make dub verbose here, the path has to be an actual binary for a few tests.
	DUB="${DUB}" DFLAGS="${filteredDflags}" FRONTEND="${DLANG_VERSION}" test/run-unittest.sh  \
		|| die "Tests failed"
}

d_src_install() {
	dobin bin/dub
	dodoc README.md

	## Currently broken with gdc
	# All the files in the directory below, with the exception of gen_man.d and README, are man pages.
	# To keep the ebuild simple, we will just glob on the files that end in .1 since there are currently
	# no man pages in a different section.
	#doman scripts/man/*.1
}
