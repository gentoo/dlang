# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="GtkD is a D binding and OO wrapper of GTK+"
HOMEPAGE="http://gtkd.org/"
LICENSE="LGPL-3"

SLOT="3"
KEYWORDS="amd64 x86"
SRC_URI="https://gtkd.org/Downloads/sources/GtkD-${PV}.zip"

DLANG_VERSION_RANGE="2.074-"
DLANG_PACKAGE_TYPE="multi"

inherit dlang

BDEPEND="app-arch/unzip"
RDEPEND="
	>=x11-libs/gtk+-3.24:3[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.60:2[${MULTILIB_USEDEP}]
	>=x11-libs/pango-1.43[${MULTILIB_USEDEP}]
	>=dev-libs/atk-2.32[${MULTILIB_USEDEP}]
	>=x11-libs/gdk-pixbuf-2.38:2[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.12.2[${MULTILIB_USEDEP}]
	sourceview? ( >=x11-libs/gtksourceview-4.2:4 )
	gstreamer? ( >=media-libs/gstreamer-1.16:1.0[${MULTILIB_USEDEP}] )
	vte? ( >=x11-libs/vte-0.56:2.91 )
	peas? ( >=dev-libs/libpeas-1.20 )
"

GTKD_USE_FLAGS=(gtk  opengl sourceview gstreamer  vte  peas)
GTKD_LIB_NAMES=(gtkd gtkdgl gtkdsv     gstreamerd vted peasd)
GTKD_SRC_DIRS=( gtkd gtkdgl sourceview gstreamer  vte  peas)
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
		local sources=generated/${SRC_DIR}/*/*.d
		if [ ${LIB_NAME} != gtkdgl ]; then
			sources+=" "generated/${SRC_DIR}/*/c/*.d
		fi
		if [ ${LIB_NAME} == gstreamerd ]; then
			sources+=" "generated/gstreamer/gst/*/*.d" "generated/gstreamer/gst/*/c/*.d
		fi
		echo $sources
		dlang_compile_lib_so lib${LIB_NAME}-${MAJOR}.so \
			lib${LIB_NAME}-${MAJOR}.so.0 -Isrc -Igenerated/gtkd ${sources}

		# Build the static library version
		if use static-libs; then
			local libname=lib${LIB_NAME}-${MAJOR}
			if [[ "${DLANG_VENDOR}" == "DigitalMars" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Isrc -Igenerated/gtkd ${sources} -lib ${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.a
			elif [[ "${DLANG_VENDOR}" == "GNU" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Isrc -Igenerated/gtkd ${sources} -c ${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.o
				dlang_exec ar rcs ${libname}.a ${libname}.o
			elif [[ "${DLANG_VENDOR}" == "LDC" ]]; then
				dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Isrc -Igenerated/gtkd ${sources} -lib -od=${SRC_DIR} -oq ${LDFLAGS} ${DLANG_OUTPUT_FLAG}${libname}.a
			fi
		fi
	}

	foreach_used_component compile_libs
}

d_src_test() {
	dlang_exec ${DC} ${DCFLAGS} -m${MODEL} -Igenerated/gtkd demos/gtkD/TestWindow/*.d ${DLANG_LINKER_FLAG}./libgtkd-3.so ${DLANG_LINKER_FLAG}-ldl ${DLANG_LINKER_FLAG}-rpath=./ ${LDFLAGS} ${DLANG_OUTPUT_FLAG}TestWindow
}

d_src_install() {
	install_libs() {
		# Install the shared library version of the component
		local libfile="lib${LIB_NAME}-${MAJOR}.so"
		ln -sf "${libfile}" "${libfile}.0"
		ln -sf "${libfile}" "${libfile}.0.${MINOR}"
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
