# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit prefix

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="https://www.gdcproject.org/"

COMMIT="b3b72f59252f09275941f706806ed80d68308db1"
SRC_URI="https://github.com/D-Programming-GDC/gdmd/archive/${COMMIT}.tar.gz -> gdmd-${COMMIT}.tar.gz"
S="${WORKDIR}/gdmd-${COMMIT}"
LICENSE="GPL-3+"

SLOT="$(ver_cut 1)"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="test" # no tests

RDEPEND="
	dev-lang/perl
	sys-devel/gcc:${SLOT}[d]
"

PATCHES="${FILESDIR}/${PN}-no-dmd-conf.patch"

src_prepare() {
	hprefixify dmd-script
	default
}

src_compile() {
	:
}

src_install() {
	local binPath="/usr/${CHOST}/gcc-bin/${SLOT}"
	exeinto "${binPath}"
	newexe dmd-script "${CHOST}-gdmd"
	dosym "${CHOST}-gdmd" "${binPath}/gdmd"

	dosym -r "${binPath}/${CHOST}-gdmd" "/usr/bin/${CHOST}-gdmd-${SLOT}"
	dosym -r "${binPath}/${CHOST}-gdmd" "/usr/bin/gdmd-${SLOT}"
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

	if [[ ${curr_config_ver} == ${SLOT} && ! ${curr_specs} ]]; then
		# We should call gcc-config to make sure the addition of gdmd is
		# propagated in $PATH. Don't do anything if not on a traditional
		# layout, the risk of breaking something outweights having the
		# script in $PATH.
		gcc-config "${CTARGET}-${SLOT}"
	fi
}
