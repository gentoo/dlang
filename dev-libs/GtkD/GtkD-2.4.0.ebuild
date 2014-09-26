# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="D binding and OO wrapper of GTK+ and is released on the LGPL license"
HOMEPAGE="http://gtkd.org/"
LICENSE="LGPL-3"

SLOT="0"
KEYWORDS="~x86 ~amd64"
SRC_URI="http://master.dl.sourceforge.net/project/gtkd-packages/sources/${P}.zip"

DLANG_VERSION_RANGE="2.063-"
DLANG_PACKAGE_TYPE="multi"

inherit eutils dlang

DEPEND="app-arch/unzip"
RDEPEND="
	>=x11-libs/gtk+-3.10:3
	sourceview? ( x11-libs/gtksourceview:3.0 )
	libgda? ( gnome-extra/libgda:4 )
	gstreamer? ( media-libs/gstreamer:1.0 )
	vte? ( x11-libs/vte:2.90 )
"

GTKD_USE_FLAGS=(gtk  opengl sourceview libgda  gstreamer    vte   )
GTKD_LIB_NAMES=(gtkd gtkdgl gtkdsv     gtkdgda gstreamerd   vted  )
GTKD_SRC_DIRS=( src  srcgl  srcsv      srcgda  srcgstreamer srcvte)
IUSE="${GTKD_USE_FLAGS[@]:1} static-libs"

MAJOR=$(get_major_version)
MINOR=$(get_after_major_version)

src_unpack() {
	unzip -q "${DISTDIR}/${A}" -d "${S}"
}

d_src_compile() {
	compile_libs() {
		# Build the shared library version of the component
		if dlang_has_shared_lib_support; then
			dlang_compile_lib.so lib${LIB_NAME}-${MAJOR}.so.0.${MINOR} \
				lib${LIB_NAME}-${MAJOR}.so.0 -Isrc ${GTKD_SRC_DIRS[$i]}/*/*.d
		else
			ewarn "${DC} does not have shared library support."
			ewarn "Only static ${LIB_NAME} will be compiled if selected through the static-libs USE flag."
		fi

		# Build the static library version
		if use static-libs; then
			local libname=lib${LIB_NAME}-${MAJOR}
			if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} ${SRC_DIR}/*/*.d -Isrc -lib \
					${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.a
			elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} ${SRC_DIR}/*/*.d -Isrc -c \
					${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.o
				dlang_exec ar rcs ${libname}.a ${libname}.o
			elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} ${SRC_DIR}/*/*.d -Isrc -lib -od=${SRC_DIR} -oq \
					${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.a
			fi
		fi
	}

	foreach_used_component compile_libs
}

d_src_install() {
	install_libs() {
		# Install the shared library version of the component
		if dlang_has_shared_lib_support; then
			local libfile="lib${LIB_NAME}-${MAJOR}.so"
			dolib.so "${libfile}.0.${MINOR}"
			dosym "${libfile}.0.${MINOR}" "/usr/$(get_libdir)/${libfile}.0"
			dosym "${libfile}.0.${MINOR}" "/usr/$(get_libdir)/${libfile}"
		fi

		# Install the static library version
		if use static-libs; then
			dolib.a "lib${LIB_NAME}-${MAJOR}.a"
		fi
	}

	foreach_used_component install_libs
}

d_src_install_all() {
	# Obligatory docs
	dodoc AUTHORS README

	# Include files
	insinto "${DLANG_IMPORT_DIR}/gtkd-${MAJOR}"

	install_headers() {
		files="${SRC_DIR}/*"
		doins -r ${files}
	}

	foreach_used_component install_headers
}

foreach_used_component() {
	for (( i = 0 ; i < ${#GTKD_LIB_NAMES[@]} ; i++ )); do
		if [[ ${GTKD_LIB_NAMES[$i]} == "gtkd" ]] || use ${GTKD_USE_FLAGS[$i]}; then
			LIB_NAME=${GTKD_LIB_NAMES[$i]} SRC_DIR=${GTKD_SRC_DIRS[$i]} ${@}
		fi
	done
}
