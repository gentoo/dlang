# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="D binding and OO wrapper of GTK+ and is released on the LGPL license"
HOMEPAGE="http://gtkd.org/"

SLOT="0"
KEYWORDS="x86 amd64"
DEPEND="app-arch/unzip"
RDEPEND="x11-libs/gtk+:3"

SRC_URI="http://master.dl.sourceforge.net/project/gtkd-packages/sources/${P}.zip"

DLANG_VERSION_RANGE="2.063-"

inherit eutils dlang

GTKD_COMP_FLAGS=(opengl sourceview libgda gstreamer vte)
GTKD_COMP_NAMES=(gtkdgl sv         gda    gstreamer vte)
IUSE="${GTKD_COMP_FLAGS[@]} static-libs"

flags_to_comps() {
	comps=("${1}gtkd")
	for (( i = 0 ; i < ${#GTKD_COMP_FLAGS[@]} ; i++ )); do
		use ${GTKD_COMP_FLAGS[$i]} && comps+=("${1}${GTKD_COMP_NAMES[$i]}")
	done
	echo ${comps[@]}
}

src_unpack() {
	unzip -q ${DISTDIR}/${A} -d ${S}
}

src_prepare() {
	epatch "${FILESDIR}/${PV}-makefile.patch"
	dlang_copy_sources
}

d_src_compile() {
	local components=()
	if dlang_has_shared_lib_support; then
		components+=($(flags_to_comps shared-))
	else
		ewarn "${DLANG_VENDOR} version ${DC_VERSION} does not have shared library support."
		ewarn "Only static libraries will be compiled if selected through the static-libs USE flag."
	fi
	if use static-libs; then
		components+=($(flags_to_comps))
	fi
	if [[ ${#components[@]} -ne 0 ]]; then
		emake ${components}
	fi
}

d_src_install() {
	if dlang_has_shared_lib_support; then
		emake DESTDIR="${D}" LIBDIR="$(get_libdir)/dlang/dmd-2.064" $(flags_to_comps "install-shared-")
	fi
	if use static-libs; then
		emake DESTDIR="${D}" LIBDIR="$(get_libdir)/dlang/dmd-2.064" $(flags_to_comps "install-")
	fi
}

src_install_all() {
	emake DESTDIR="${D}" $(flags_to_comps "install-headers-")
	dodoc AUTHORS README COPYING
}