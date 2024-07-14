# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib-minimal

DESCRIPTION="GtkD is a D binding and OO wrapper of GTK+"
HOMEPAGE="https://gtkd.org/"
SRC_URI="https://gtkd.org/Downloads/sources/GtkD-${PV}.zip"
LICENSE="LGPL-3"

SLOT="3"
KEYWORDS="~amd64 ~x86"

MULTILIB_COMPAT=( abi_x86_{32,64} )
DLANG_COMPAT=( dmd-2_{106..109} gdc-1{3,4} ldc2-1_{35..39} )
declare -A DLANG_REQ_USE=(
	[dmd]="${MULTILIB_USEDEP}"
	[gdc]=""
	[ldc2]="${MULTILIB_USEDEP}"
)

inherit dlang-r1

BDEPEND="app-arch/unzip ${DLANG_DEPS}"
RDEPEND="
	${DLANG_DEPS}
	>=x11-libs/gtk+-3.24:3[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.64:2[${MULTILIB_USEDEP}]
	>=x11-libs/pango-1.43[${MULTILIB_USEDEP}]
	>=app-accessibility/at-spi2-core-2.34[${MULTILIB_USEDEP}]
	>=x11-libs/gdk-pixbuf-2.38:2[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.12.2[${MULTILIB_USEDEP}]
	>=gnome-base/librsvg-2.54:2[${MULTILIB_USEDEP}]
	sourceview? ( >=x11-libs/gtksourceview-4.2:4 )
	gstreamer? ( >=media-libs/gstreamer-1.16:1.0[${MULTILIB_USEDEP}] )
	vte? ( >=x11-libs/vte-0.56:2.91 )
	peas? ( >=dev-libs/libpeas-1.20 )
"
DEPEND=${DLANG_DEPS}

GTKD_USE_FLAGS=(gtk  opengl sourceview gstreamer  vte  peas)
GTKD_LIB_NAMES=(gtkd gtkdgl gtkdsv     gstreamerd vted peasd)
GTKD_SRC_DIRS=( gtkd gtkdgl sourceview gstreamer  vte  peas)
# static-libs I have no idea about. It makes a "static-library" that
# dynamically links phobos and uses dl to open the gtk+ libs at runtime.
IUSE="${GTKD_USE_FLAGS[@]:1} static-libs"
REQUIRED_USE=${DLANG_REQUIRED_USE}

MAJOR=$(ver_cut 1)
MINOR=$(ver_cut 2-)

src_unpack() {
	mkdir "${S}" || die "Could not create source directory"
	pushd "${S}" >/dev/null || die
	unpack "${A}"
	popd >/dev/null || die
}

src_prepare() {
	default

	multilib_copy_sources
	multilib_foreach_abi dlang_copy_sources
}

multilib_src_compile() {
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

		local imports="src generated/gtkd"
		# avoid file name collisions with ldc2
		[[ ${EDC} == ldc2* ]] && local DCFLAGS="${DCFLAGS} -oq"
		dlang_compile_lib.so lib${LIB_NAME}-${MAJOR}.so \
			lib${LIB_NAME}-${MAJOR}.so.0 ${sources}
		# Build the static library version.
		use static-libs && dlang_compile_lib.a "lib${LIB_NAME}-${MAJOR}.a" "${sources}"

		# Generate the pkg-config file. The make rules don't depend on anything so
		# it's fine to use them even though we compiled the library in another way.

		local mymakeargs=(
			LINKERFLAG="$(dlang_get_linker_flag)"
			prefix="${EPREFIX}/usr"
			libdir="$(dlang_get_libdir)"
		)
		emake "${mymakeargs[@]}" "${LIB_NAME}-${MAJOR}.pc"
		sed -i -e 's@include/d@include/dlang@' "${LIB_NAME}-${MAJOR}.pc" || \
			die "Could not modify include path for ${LIB_NAME}-${MAJOR}.pc"
	}

	dlang_foreach_impl foreach_used_component compile_libs
}

multilib_src_test() {
	simple_test() {
		local cmd=(
			${DC} ${DCFLAGS} ${DLANG_LDFLAGS}
			$(dlang_get_model_flag)
			-Igenerated/gtkd
			demos/gtkD/TestWindow/*.d
			$(dlang_get_linker_flag)./libgtkd-3.so
			$(dlang_get_linker_flag)-ldl
			$(dlang_get_linker_flag)-rpath=./
			$(dlang_get_output_flag)TestWindow
		)

		dlang_exec "${cmd[@]}"

		if use static-libs; then
			cmd=(
				${DC} ${DCFLAGS} ${DLANG_LDFLAGS}
				$(dlang_get_model_flag)
				-Igenerated/gtkd
				demos/gtkD/TestWindow/*.d
				./libgtkd-3.a
				$(dlang_get_output_flag)TestWindow-static
			)

			dlang_exec "${cmd[@]}"
		fi
	}

	multilib_is_native_abi && dlang_foreach_impl simple_test
}

multilib_src_install() {
	install_libs() {
		# Install the shared library version of the component
		local libfile="lib${LIB_NAME}-${MAJOR}.so"
		ln -sf "${libfile}" "${libfile}.0"
		ln -sf "${libfile}" "${libfile}.0.${MINOR}"
		dlang_dolib.so "${libfile}.0.${MINOR}" "${libfile}.0" "${libfile}"

		# Install the static library version
		if use static-libs; then
			dlang_dolib.a "lib${LIB_NAME}-${MAJOR}.a"
		fi

		# Install the pkg-config files
		insinto "/usr/$(dlang_get_libdir)/pkgconfig"
		doins "${LIB_NAME}-${MAJOR}.pc"
	}

	dlang_foreach_impl foreach_used_component install_libs
}

multilib_src_install_all() {
	# Obligatory docs
	dodoc AUTHORS README.md

	install_headers() {
		# Include files. dlang_get_import_dir is safe to use outside of
		# dlang_foreach_impl.
		insinto "$(dlang_get_import_dir)/${PN}-${MAJOR}"

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
