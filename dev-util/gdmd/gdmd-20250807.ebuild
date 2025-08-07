# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DLANG_COMPAT=( gdc-1{2..5} )
inherit dlang-r1 prefix

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="https://www.gdcproject.org/"

COMMIT="d14f7301b4bbae44996bc962121c9a1e7f7e3f12"
SRC_URI="https://github.com/D-Programming-GDC/gdmd/archive/${COMMIT}.tar.gz -> gdmd-${COMMIT}.tar.gz"
S="${WORKDIR}/gdmd-${COMMIT}"
LICENSE="GPL-3+"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="test" # no tests

REQUIRED_USE=${DLANG_REQUIRED_USE}
# Ignore ${DLANG_DEPS}, we only need gcc[d]
gen_gccslot_dep() {
	local impl dep=${1} result=()
	for impl in "${_DLANG_SUPPORTED_IMPLS[@]}"; do
		local slot=${impl#gdc-}
		local req=dlang_targets_${impl}

		local subdep=${dep//\$\{GCC_SLOT\}/${slot}}
		result+=( "${req}? ( ${subdep} )" )
	done

	echo "${result[@]}"
}
RDEPEND="
	dev-lang/perl
	$(gen_gccslot_dep '
			sys-devel/gcc:${GCC_SLOT}[d]
			!<dev-util/gdmd-${GCC_SLOT}.20250807:${GCC_SLOT}
	')
"

PATCHES=(
	"${FILESDIR}/${PN}-20250807-no-dmd-conf.patch"
)

src_prepare() {
	hprefixify dmd-script
	default

	dlang_copy_sources
}

src_compile() {
	:
}

src_install() {
	doinstall() {
		local slot=${EDC#gdc-}
		local binPath="/usr/${CHOST}/gcc-bin/${slot}"
		exeinto "${binPath}"
		newexe dmd-script "${CHOST}-gdmd"
		dosym "${CHOST}-gdmd" "${binPath}/gdmd"

		dosym -r "${binPath}/${CHOST}-gdmd" "/usr/bin/${CHOST}-gdmd-${slot}"
		dosym -r "${binPath}/${CHOST}-gdmd" "/usr/bin/gdmd-${slot}"
	}
	dlang_foreach_impl doinstall

	newman "${S}/dmd-script.1" gdmd.1
}

pkg_postinst() {
	maybe_update_gcc_config
}

# We can't really call gcc-config in postrm since it won't know which
# symlinks under /usr/bin were left by us. If it turns out to be a
# problem we could try to remove the symlink manually.

maybe_update_gcc_config() {
	# Call gcc-config if the current configuration if for the same slot
	# we are installing to. This is needed to make gdmd available in
	# $PATH.

	local CTARGET=${CTARGET:-${CHOST}}

	# Logic taken from toolchain.eclass and simplified a little
	local curr_config
	curr_config=$(gcc-config -c ${CTARGET} 2>&1) || return 0

	local curr_config_ver=$(gcc-config -S ${curr_config} | awk '{print $2}')
	local curr_specs=$(gcc-config -S ${curr_config} | awk '{print $3}')
	local exp_USE=dlang_targets_gdc-${curr_config_ver}

	# We should call gcc-config to make sure the addition of gdmd is
	# propagated in $PATH, if the currently eselected gcc matches a slot
	# that we are targeting. Don't do anything if not on a traditional
	# layout, the risk of breaking something outweighs having the
	# script in $PATH.
	[[ ${curr_specc} ]] && return 0
	! has "${exp_USE}" ${IUSE} && return 0
	! use "${exp_USE}" && return 0

	gcc-config "${CTARGET}-${curr_config_ver}"
}
