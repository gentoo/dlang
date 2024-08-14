# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV="$(ver_rs 3 - 4 .)" # 0.8.0_beta15 -> 0.8.0-beta.15
# gdc currently fails due to a bug in mir-cpuid, see: https://github.com/libmir/mir-cpuid/pull/46
DLANG_COMPAT=( dmd-2_{106..109} ldc2-1_{35..39} )
DUB_DEPENDENCIES=(
	"automem@0.6.9"
	"cachetools@0.4.1"
	"dcd@0.16.0-beta.2"
	"dfmt@0.15.1"
	"diet-complete@0.0.3"
	"diet-ng@1.8.1"
	"dscanner@0.16.0-beta.4"
	"dub@1.36.0"
	"emsi_containers@0.9.0"
	"eventcore@0.9.28"
	"fuzzymatch@1.0.0"
	"inifiled@1.3.3"
	"isfreedesktop@0.1.1"
	"libasync@0.8.6"
	"libddoc@0.8.0"
	"libdparse@0.23.2"
	"memutils@1.0.10"
	"mir-algorithm@3.21.0"
	"mir-core@1.7.0"
	"mir-cpuid@1.2.11"
	"mir-ion@2.2.1"
	"mir-linux-kernel@1.0.1"
	"msgpack-d@1.0.5"
	"openssl@3.3.3"
	"openssl-static@1.0.2+3.0.8"
	"requests@2.1.3"
	"rm-rf@0.1.0"
	"sdlfmt@0.1.1"
	"sdlite@1.1.2"
	"serve-d@0.8.0-beta.17"
	"silly@1.1.1"
	"standardpaths@0.8.2"
	"stdx-allocator@2.77.5"
	"taggedalgebraic@0.11.22"
	"test_allocator@0.3.4"
	"unit-threaded@0.10.8"
	"vibe-container@1.1.0"
	"vibe-core@2.7.4"
	"vibe-d@0.9.7"
	"xdgpaths@0.2.5"
)
inherit check-reqs dlang-single dub multiprocessing
DUB_TEST_DEP="gitcompatibledubpackage@1.0.4"

DESCRIPTION="Microsoft language server protocol implementation for D"
HOMEPAGE="https://github.com/Pure-D/serve-d"
SRC_URI="
	${DUB_DEPENDENCIES_URIS}
	test? ( $(dub_dependencies_uris "${DUB_TEST_DEP}") )
"
S="${WORKDIR}/${PN}-${MY_PV}"
LICENSE="MIT BSD"
LICENSE+=" Apache-2.0 Boost-1.0 BSD GPL-3 LGPL-3 MIT openssl public-domain Unlicense"
LICENSE+=" test? ( ISC public-domain )" # test dependencies. These do _not_ map to test? () in SRC_URI
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

CHECKREQS_MEMORY="10G" # mir is a chonker

# Lower versions of dcd won't immediately fail but they won't work as
# intended (no autocompletion for example).
COMMON_DEPEND=">=dev-util/dcd-0.15.2"
RDEPEND+=" ${COMMON_DEPEND}"
BDEPEND+=" test? ( ${COMMON_DEPEND} )"

src_unpack() {
	dub_src_unpack
	use test && dub_copy_dependencies_locally "${DUB_TEST_DEP}"
}

src_configure() {
	# There's an issue with ldc that when -mcpu=native is specified you
	# get an llvm stack trace. It seems to be related to the use of
	# certain intrinsics that depend on the target cpu.
	if [[ ${EDC} == ldc2* && ${DCFLAGS} == *-mcpu=native* ]]; then
		ewarn "-mcpu=native causes issues with ldc2 so it will be removed"
		ewarn "from your flags."
		ewarn "See: https://github.com/libmir/mir-ion/pull/46"
	fi
	dlang-filter-dflags "ldc2*" "-mcpu=native"

	# See https://issues.dlang.org/show_bug.cgi?id=24406 and
	# https://github.com/Pure-D/serve-d/issues/360
	# In short, we have to remove -O from DCFLAGS for dmd.
	if [[ ${EDC} == dmd* && ${DCFLAGS} == *-O* ]]; then
		ewarn "Optimizations will be turned off for this build with dmd"
		ewarn "See: https://github.com/Pure-D/serve-d/issues/360"
	fi
	dlang-filter-dflags "dmd*" "-O*"
}

src_test() {
	# Tests all submodules in dub.json.
	local subpkg
	for subpkg in ":http" ":protocol" ":lsp" ":serverbase" ":dcd" ":workspace-d" ""; do
		edub test ${subpkg} --build=unittest -- --threads="$(makeopts_jobs)"
	done

	edub build --root=null_server
	edub run --root=null_server_test

	# A simplified version for ${S}/test/runtests.sh
	pushd test > /dev/null || die

	# Tries to update dependencies timing out for each one which sums up
	# to about 4 minutes of doing nothing. There is no direct way to
	# configure the code not to contact https://code.dlang.org
	rm -rf tc_dub || die
	# Uses basename to run compiler binaries which happens to work since
	# dlang-utils.eclass creates symlinks for them. Like tc_dub spends
	# ~40 seconds waiting for code.dlang.org
	rm -rf tc_dub_empty || die

	local testcase
	for testcase in tc*; do
		pushd "${testcase}" > /dev/null || die
		einfo "Running testcase ${testcase}"
		edub run
		popd > /dev/null || die
	done
	popd > /dev/null || die
}

src_install() {
	dobin "${S}/serve-d"
	dodoc README.md editor-*.md
}

pkg_postinst() {
	elog "You will need to configure your editor to use serve-d."
	elog "For instructions check out the README and editor-* files in"
	elog "  ${EROOT}/usr/share/doc/${PF}"
}
