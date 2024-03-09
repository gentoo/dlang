# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Swiss-army knife for D source code"
HOMEPAGE="https://github.com/dlang-community/D-Scanner"
LICENSE="Boost-1.0"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="debug"

CONTAINERS="116a02872039efbd0289828cd5eeff6f60bdf539"
DCD="1c60c5480f70db568279e4637a5033953c777406"
INIFILED="cecaff8037a60db2a51c9bded4802c87d938a44e"
LIBDDOC="fbbfb8245728484e5f96d717994d4b404a9789a4"
LIBDPARSE="fe6d1e38fb4fc04323170389cfec67ed7fd4e24a"
GITHUB_URI="https://codeload.github.com"
SRC_URI="
	${GITHUB_URI}/dlang-community/${PN}/tar.gz/v${PV} -> ${P}.tar.gz
	${GITHUB_URI}/dlang-community/containers/tar.gz/${CONTAINERS} -> containers-${CONTAINERS}.tar.gz
	${GITHUB_URI}/dlang-community/DCD/tar.gz/${DCD} -> DCD-${DCD}.tar.gz
	${GITHUB_URI}/burner/inifiled/tar.gz/${INIFILED} -> inifiled-${INIFILED}.tar.gz
	${GITHUB_URI}/dlang-community/libddoc/tar.gz/${LIBDDOC} -> libddoc-${LIBDDOC}.tar.gz
	${GITHUB_URI}/dlang-community/libdparse/tar.gz/${LIBDPARSE} -> libdparse-${LIBDPARSE}.tar.gz
	"
S="${WORKDIR}/D-Scanner-${PV}"
PATCHES=( "${FILESDIR}/${PV}-makefile-fixes.patch" )

DLANG_COMPAT=( dmd-2_{106..107} gdc-13 ldc2-1_{35..36} )

inherit dlang-single

REQUIRED_USE=${DLANG_REQUIRED_USE}
DEPEND=${DLANG_DEPS}
BDEPEND=${DLANG_DEPS}
RDEPEND=${DLANG_DEPS}

src_prepare() {
	move_git_submodules

	mkdir "${S}"/bin || die "Failed to create 'bin' directory."
	# Stop the makefile from executing git
	echo "v${PV}" > "${S}"/bin/githash.txt || die "Could not generate githash"

	# Apply patches
	default
}

src_compile() {
	if use debug; then
		# Add a -debug compiler specific flag and enable the dparse_verbose version,
		# like the debug target in the makefile except that it doesn't build everything in 1 go.
		DCFLAGS+=" $(dlang_get_version_flag)=dparse_verbose"

		local debugFlag
		case "${EDC}" in
			dmd*) debugFlag="-debug" ;;
			gdc*) debugFlag="-fdebug" ;;
			ldc*) debugFlag="-d-debug" ;;
		esac
		DCFLAGS+=" ${debugFlag}"
	fi

	emake DFLAGS="${DCFLAGS}"
}

src_test() {
	# We can specify user flags in (DMD|LDC|GDC)_TEST_FLAGS
	local flagName=${EDC::3}
	flagName="${flagName^^}_TEST_FLAGS"

	emake test "${flagName}=${DCFLAGS}"
}

src_install() {
	dobin bin/dscanner
	dodoc README.md LICENSE_1_0.txt
}

move_git_submodules() {
	# Move all submodule dependencies into the appropriate folders.
	# They have to be moved from ${WORKDIR}/${name}-${hash} to ${S}/${name}
	local submodule submodules=(
		"containers" "DCD" "inifiled" "libddoc" "libdparse"
	)
	for submodule in "${submodules[@]}"; do
		# make the name uppercase: inifiled -> INIFILED
		local submodule_hash_var="${submodule^^}"
		# and extract the hash
		local submodule_hash="${!submodule_hash_var}"

		local submodule_directory="${WORKDIR}/${submodule}-${submodule_hash}"

		mv -T "${submodule_directory}" "${S}/${submodule}" \
		   || die "Could not move submodule '${submodule}' to its subdirectory"
	done
}
