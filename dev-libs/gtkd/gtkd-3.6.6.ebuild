# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="GtkD is a D binding and OO wrapper of GTK+"
HOMEPAGE="http://gtkd.org/"
LICENSE="LGPL-3"

SLOT="3"
KEYWORDS="~x86 ~amd64"
SRC_URI="http://gtkd.org/Downloads/sources/GtkD-${PV}.zip"

DLANG_VERSION_RANGE="2.068-"
DLANG_PACKAGE_TYPE="multi"

inherit eutils dlang

DEPEND="app-arch/unzip"
RDEPEND="
	>=x11-libs/gtk+-3.22:3[${MULTILIB_USEDEP}]
	sourceview? ( >=x11-libs/gtksourceview-3.24:3.0 )
	gstreamer? ( >=media-libs/gstreamer-1.12:1.0 )
	vte? ( >=x11-libs/vte-0.48:2.91 )
	peas? ( >=dev-libs/libpeas-1.20 )
"

GTKD_USE_FLAGS=(gtk  opengl sourceview gstreamer  vte  peas)
GTKD_LIB_NAMES=(gtkd gtkdgl gtkdsv     gstreamerd vted peasd)
GTKD_SRC_DIRS=( gtkd gtkdgl sourceview gstreamer  vte  peas)
IUSE="${GTKD_USE_FLAGS[@]:1} static-libs"

MAJOR=$(get_major_version)
MINOR=$(get_after_major_version)

src_unpack() {
	unzip -q "${DISTDIR}/${A}" -d "${S}"
}

d_src_compile() {
	compile_libs() {
		# Build the shared library version of the component
		# The test phase expects no version extension on the .so
		if dlang_has_shared_lib_support; then
			dlang_compile_lib_so lib${LIB_NAME}-${MAJOR}.so \
				lib${LIB_NAME}-${MAJOR}.so.0 -Isrc -Igenerated/gtkd generated/${SRC_DIR}/*/*.d
		else
			ewarn "${DC} does not have shared library support."
			ewarn "Only static ${LIB_NAME} will be compiled if selected through the static-libs USE flag."
		fi

		# Build the static library version
		if use static-libs; then
			local libname=lib${LIB_NAME}-${MAJOR}
			if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Isrc -Igenerated/gtkd generated/${SRC_DIR}/*/*.d -lib ${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.a
			elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Isrc -Igenerated/gtkd generated/${SRC_DIR}/*/*.d -c ${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.o
				dlang_exec ar rcs ${libname}.a ${libname}.o
			elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Isrc -Igenerated/gtkd generated/${SRC_DIR}/*/*.d -lib -od=${SRC_DIR} -oq ${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.a
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
		if dlang_has_shared_lib_support; then
			local libfile="lib${LIB_NAME}-${MAJOR}.so"
			ln -sf "${libfile}" "${libfile}.0"
			ln -sf "${libfile}" "${libfile}.0.${MINOR}"
			dolib.so "${libfile}.0.${MINOR}" "${libfile}.0" "${libfile}"
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
	dodoc AUTHORS README.md

	# Include files
	insinto "${DLANG_IMPORT_DIR}/${PN}-${MAJOR}"

	install_headers() {
		files="generated/${SRC_DIR}/*"
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
