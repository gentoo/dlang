# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="D binding and OO wrapper of GTK+ and is released on the LGPL license"
HOMEPAGE="http://gtkd.org/"
LICENSE="LGPL-3"

SLOT="2"
KEYWORDS="amd64 x86"
SRC_URI="https://gtkd.org/Downloads/sources/GtkD-${PV}.zip"

# 2.068 through 2.070 suffer from https://forum.gtkd.org/groups/GtkD/thread/302/
DLANG_VERSION_RANGE="2.063-2.067 2.071-2.080"
DLANG_PACKAGE_TYPE="multi"

inherit eutils dlang

DEPEND="app-arch/unzip"
RDEPEND="
	>=x11-libs/gtk+-3.10:3[${MULTILIB_USEDEP}]
	sourceview? ( >=x11-libs/gtksourceview-3.10:3.0 )
	gstreamer? ( >=media-libs/gstreamer-1.2:1.0 )
	vte? ( >=x11-libs/vte-0.37.4:2.91 )
"

GTKD_USE_FLAGS=(gtk  opengl sourceview libgda  gstreamer    vte   )
GTKD_LIB_NAMES=(gtkd gtkdgl gtkdsv     gtkdgda gstreamerd   vted  )
GTKD_SRC_DIRS=( src  srcgl  srcsv      srcgda  srcgstreamer srcvte)
IUSE="${GTKD_USE_FLAGS[@]:1} static-libs"

MAJOR=$(ver_cut 1)
MINOR=$(ver_cut 2-)

src_unpack() {
	unzip -q "${DISTDIR}/${A}" -d "${S}"
}

d_src_compile() {
	compile_libs() {
		# Build the shared library version of the component
		# The test phase expects no version extension on the .so
		dlang_compile_lib_so lib${LIB_NAME}-${MAJOR}.so \
			lib${LIB_NAME}-${MAJOR}.so.0 -Isrc ${GTKD_SRC_DIRS[$i]}/*/*.d

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

d_src_test() {
	emake LINKERFLAG="${DLANG_LINKER_FLAG}" output="${DLANG_OUTPUT_FLAG}\$@" test
}

d_src_install() {
	install_libs() {
		# Install the shared library version of the component
		local libfile="lib${LIB_NAME}-${MAJOR}.so"
		ln -s "${libfile}" "${libfile}.0"
		ln -s "${libfile}" "${libfile}.0.${MINOR}"
		dolib.so "${libfile}.0.${MINOR}" "${libfile}.0" "${libfile}"

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
	insinto "${DLANG_IMPORT_DIR}/${PN}-${MAJOR}"

	install_headers() {
		files="${SRC_DIR}/*"
		doins -r ${files}
	}

	foreach_used_component install_headers
}

foreach_used_component() {
	for (( i = 0 ; i < ${#GTKD_LIB_NAMES[@]} ; i++ )); do
		if [[ "${GTKD_LIB_NAMES[$i]}" == "gtkd" ]] || use ${GTKD_USE_FLAGS[$i]}; then
			LIB_NAME=${GTKD_LIB_NAMES[$i]} SRC_DIR=${GTKD_SRC_DIRS[$i]} ${@}
		fi
	done
}
