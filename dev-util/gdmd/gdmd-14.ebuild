# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Wrapper script for gdc that emulates the dmd command"
HOMEPAGE="https://www.gdcproject.org/"

RELEASE="0.1.0"
SRC_URI="https://codeload.github.com/D-Programming-GDC/gdmd/tar.gz/script-${RELEASE} -> gdmd-${RELEASE}.tar.gz"
S="${WORKDIR}/gdmd-script-${RELEASE}"
LICENSE="GPL-3+"

SLOT="${PV}"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="test" # no tests

RDEPEND="sys-devel/gcc:${PV}[d]"

PATCHES="${FILESDIR}/${PN}-no-dmd-conf.patch"

src_compile() {
	:
}

src_install() {
	local binPath="/usr/${CHOST}/gcc-bin/${PV}"
	exeinto "${binPath}"
	newexe dmd-script "${CHOST}-gdmd"
	dosym "${CHOST}-gdmd" "${binPath}/gdmd"
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

	if [[ ${curr_config_ver} == ${SLOT}  && ! ${curr_specs} ]]; then
		# We should call gcc-config to make sure the addition of gdmd is
		# propagated in $PATH. Don't do anything if not on a traditional
		# layout, the risk of breaking something outweights having the
		# script in $PATH.
		gcc-config "${CTARGET}-${SLOT}"
	fi
}
