# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Dfmt is a formatter for D source code"
HOMEPAGE="https://github.com/dlang-community/dfmt"

LIBDPARSE="fe6d1e38fb4fc04323170389cfec67ed7fd4e24a"
SRC_URI="
	https://github.com/dlang-community/dfmt/archive/v${PV}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/dlang-community/libdparse/archive/${LIBDPARSE}.tar.gz -> libdparse-${LIBDPARSE}.tar.gz
	"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

DLANG_COMPAT=( dmd-2_{106..108} gdc-1{3,4} ldc2-1_{35..38} )

inherit dlang-single bash-completion-r1

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}

src_prepare() {
	mv -T "../libdparse-${LIBDPARSE}" libdparse || die "Couldn't move submodule libdparse"
	# Make a dummy folder to silence a find warning in the makefile
	mkdir -p stdx-allocator/source || die "Couldn't create dummy stdx-allocator directory"

	default

	mkdir bin || die "Failed to create 'bin' directory."
	echo "v${PV}" > bin/githash.txt
	touch githash

	# Use our user's flags + $(INCLUDE_PATHS) defined in the makefile
	export D_FLAGS="$(dlang_get_dmdw_dcflags) $(dlang_get_dmdw_ldflags) \$(INCLUDE_PATHS)"
	# Tests fail with -march=native and -O2 with <sys-devel/gcc-13.2.1_p20240330,
	# probably https://gcc.gnu.org/bugzilla/show_bug.cgi?id=114171 again.
	if [[ ${EDC} == gdc-13 && ${D_FLAGS} == *-march=native* ]]; then
		ewarn '-march=native has been removed from your flags.'
		ewarn 'See: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=114171'
		# Interestingly `-q,` is a valid gdmd flag.
		export D_FLAGS=${D_FLAGS//-march=native}
	fi
}

src_compile() {
	emake DC="$(dlang_get_dmdw)" DMD_FLAGS="${D_FLAGS}"
}

src_test() {
	# minimal workaround for https://github.com/dlang-community/dfmt/pull/600
	touch githash.d
	# Let the makefile add -unittest -g, keeps our code simpler
	emake bin/dfmt-test DC="$(dlang_get_dmdw)" DMD_COMMON_FLAGS="${D_FLAGS}"
	./bin/dfmt-test || die "Unittests failed"

	cd tests || die

	dlang_compile_bin "run_tests" "test.d"
	./run_tests || die "Tests failed"
}

src_install() {
	dobin bin/dfmt
	dodoc README.md LICENSE.txt
	dobashcomp bash-completion/completions/dfmt
}
