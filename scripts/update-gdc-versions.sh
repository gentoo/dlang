#!/bin/bash
# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

###### Usage ######
# ./update-gdc-versions.sh [-a]
#
# Update all gdc related variables in this overlay:
# 1. gdmd keywords
# 2. dlang-compilers.eclass
# 3. use.desc
# based on the gcc versions currently available in ::gentoo.
#
# You will be prompted for you sudo/doas password at the end to
# extract the dmd version from the gcc sources because the ebuild
# command requires elevated privileges. Alternatively you may run this
# script as root.
#
# By default, only 1 gcc version for each gdmd slot needs to be
# extracted. Otherwise, when the -a option is passed, force check of
# (almost) all gcc ebuilds. This will prompt for your sudo/doas password
# more so it may be worth to run the script as root in this case.
###### End Usage ######

# This script uses various utilities from app-portage/portage-utils

# No -u because /lib/gentoo/functions.sh doesn't work with it
set -eo pipefail
shopt -s nullglob

source /lib/gentoo/functions.sh

REPO="$(dirname "${0}")"
cd "${REPO}/.."
readonly EROOT=$(portageq envvar EROOT)
readonly PORTDIR=$(portageq get_repo_path "${EROOT}" gentoo)
[[ ${1} == "-a" ]] && readonly CHECK_ALL=1 || readonly CHECK_ALL=0

# Associative array betwen gcc $PVRs and their keywords
declare -A GCC_TO_KEYWORDS
# Associative array between gcc slots (gdmd versions) and a combination
# of the keywords of each gcc version in said slot.
declare -A SLOT_TO_KEYWORDS
# Program to use for running privileged commands.
# The user may specify this manually, or it will be autodetected.
declare SUDO

die () {
	eerror "${@}"
	exit 1
}

keyword_to_arch () {
	[[ $# -ne 1 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}"

	if [[ ${1:0:1} == @(-|~) ]]; then
		echo "${1:1}"
	else
		echo "${1}"
	fi
}

keyword_to_stability () {
	[[ $# -ne 1 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}, expected 1"

	if [[ ${1:0:1} = '-' ]]; then
		echo 0
	elif [[ ${1:0:1} = '~' ]]; then
		echo 1
	else
		echo 2
	fi
}

# Combines 2 keywords for the same arch so that the more stable one is chosen
# amd64 - stable
# ~amd64 - unstable
# -amd64 - disabled
combine_arch_keywords () {
	[[ $# -ne 2 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}, expected 2"
	local k1="${1}" k2="${2}"
	[[ $(keyword_to_arch $k1) != $(keyword_to_arch $k2) ]] && \
		die "Internal error: ${FUNCNAME} got keywords for difference arches"


	local s1=$(keyword_to_stability "${k1}")
	local s2=$(keyword_to_stability "${k2}")

	if [[ $s1 -ge $s2 ]]; then
		echo "${k1}"
	else
		echo "${k2}"
	fi
}

# Given 2 list of keywords returns a new list with the most stable keywords taken
# from both lists
combine_keywords () {
	[[ $# -ne 2 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}, exptected 2"
	local v1=($1) v2=($2) # We want the expansion

	# We take advantage that the keyword arrays are sorted
	local n=${#v1[@]} m=${#v2[@]}
	local i=0 j=0

	local result=()

	while (( i < n && j < m )); do
		local a1=$(keyword_to_arch "${v1[i]}")
		local a2=$(keyword_to_arch "${v2[j]}")

		if [[ $a1 = $a2 ]]; then
			result+=("$(combine_arch_keywords "${v1[i]}" "${v2[j]}")")
			((++i, ++j)) || true
		elif [[ $a1 < $a2 ]]; then
			result+=("${v1[i]}")
			((++i)) || true
		else
			result+=("${v2[j]}")
			((++j)) || true
		fi
	done

	result+=("${v1[@]:i}")
	result+=("${v2[@]:j}")

	echo "${result[@]}"
}

# Check if there is an ebuild of gdmd for a specific version of gcc.
# $1 can either be a gcc slot of a gcc version, they are both calculated
# in the same way.
can_handle () {
	[[ $# -ne 1 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}, exptected 1"

	local slot="${1%%\.*}"

	[[ -f "dev-util/gdmd/gdmd-${slot}.ebuild" ]]
}

# Run a privileged command
asroot () {
	[[ $# -eq 0 ]] && die "Internal error: Didn't pass any arguments to ${FUNCNAME}"
	if [[ ${EUID} -ne 0 && -z ${SUDO} ]]; then
		# Check for either sudo or doas in PATH
		if type -P sudo > /dev/null; then
			SUDO=sudo
		elif type -P doas > /dev/null; then
			SUDO=doas
		else
			die "Didn't find any command for privilege escalation"
		fi
	fi

	echo "Running: ${SUDO} ${@}"
	# Let $SUDO be shell expanded in case it is empty
	${SUDO} "${@}"
}

# Get the dmd version from a gcc PVR
get_gcc_dmd_version () {
	[[ $# -ne 1 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}, expected 1"
	version="${1}"

	ebuild="${PORTDIR}/sys-devel/gcc/gcc-${version}.ebuild"
	# Pass the ebuild output on stderr
	asroot ebuild "${ebuild}" unpack >&2

	prefix="$(portageq envvar PORTAGE_TMPDIR)/portage/sys-devel/gcc-${version}"

	# Make /var/tmp/portage/sys-devel/gcc* traversable for the normal user
	# to prevent asking for the root password for each file we want to check.
	asroot chmod +rx "${prefix}" "${prefix}/work" >&2

	# I don't know another way to explicitly expand the *
	path=$(echo "${prefix}/work/gcc-"*/gcc/d/dmd/VERSION)

	if [[ -f ${path} ]]; then
		dmdVersion=$(cat "${path}")
		# The version in $path looks like: v2.100.1 or v2.103.0-rc.1
		dmdVersion=${dmdVersion#v}
		dmdVersion=${dmdVersion%-*} # In case there's a -rc.x component
		dmdVersion=${dmdVersion%.*}
	else
		# This one is always present
		merge_file=$(echo "${prefix}/work/gcc-"*/gcc/d/dmd/MERGE)
		[[ ! -f ${merge_file} ]] && die "Can not access '${merge_file}'"
		if [[ $(head -n1 ${merge_file}) = "0450061c8de71328815da9323bd35c92b37d51d2" ]]; then
			# A common commit id with dmd version 2.076
			dmdVersion="2.076"
		else
			dmdVersion="<CHANGEME>"
		fi
	fi

	asroot ebuild "${ebuild}" clean >&2

	echo "${dmdVersion}"
}

# Find the keywords for each gcc ebuild (that support d)
while read -r keywords; do
	filename="${keywords%:*}"
	keywords="${keywords#*KEYWORDS=\"}"
	keywords="${keywords%\"}"

	version="$(qatom -F'%{PVR}' "${filename}")"

	if [[ $version =~ .*9999.* ]]; then
		# Don't include live ebuilds
		continue
	fi

	# Filter out hppa and sparc keywords
	keyarr=(${keywords})
	for (( i=0; i<"${#keyarr[@]}"; ++i)); do
		[[ $(keyword_to_arch "${keyarr[$i]}") == @(hppa|sparc) ]] && unset "keyarr[$i]"
	done
	keywords="${keyarr[@]}"

	quse -ep "sys-devel/gcc-${version}" | egrep -wq '[+-]?d' && \
		GCC_TO_KEYWORDS[${version}]="${keywords}"

done < <(egrep "^\s*KEYWORDS" "${PORTDIR}/sys-devel/gcc/gcc"*)

# Merge all the KEYWORDS in a slot into a single list
for version in "${!GCC_TO_KEYWORDS[@]}"; do
	slot="${version%%\.*}"

	if [[ ! -v SLOT_TO_KEYWORDS[${slot}] ]]; then
		SLOT_TO_KEYWORDS[${slot}]="${GCC_TO_KEYWORDS[${version}]}"
	else
		SLOT_TO_KEYWORDS[${slot}]=$(combine_keywords \
										"${SLOT_TO_KEYWORDS[${slot}]}" \
										"${GCC_TO_KEYWORDS[${version}]}")
	fi
done

###### Modify keywords for each gdmd ebuild and gdc USE flags #######
declare -a GDC_TARGETS
for slot in "${!SLOT_TO_KEYWORDS[@]}"; do
	if ! can_handle "${slot}"; then continue; fi

	file="dev-util/gdmd/gdmd-${slot}.ebuild"
	sed -i -e 's/^KEYWORDS=.*$/KEYWORDS="'"${SLOT_TO_KEYWORDS[$slot]}"'"/' "${file}"

	if [[ ${CHECK_ALL} == 0 ]]; then
		atom="$(portageq best_visible "${EROOT}" "sys-devel/gcc:${slot}")"
		version="${atom##*-}"

		dmdVersion="$(get_gcc_dmd_version "${version}")"
		[[ -z ${dmdVersion} ]] && dmdVersion="<CHANGEME>"

		# We skip adding the [" that should be at the begining so we
		# can properly sort the array later.
		GDC_TARGETS+=("${slot}\"]=\"${dmdVersion} ${SLOT_TO_KEYWORDS[${slot}]}\"")
	else
		# Avoid multiple extractions for the same ebuild.
		# Let the code below generate the targets
		:
	fi
done

###### Verify all gcc ebuilds ######
if [[ ${CHECK_ALL} == 1 ]]; then
	# Theoretically, we only need to check 1 version for each slot but,
	# for safety, check them all and see if all versions in 1 slot
	# have the same dmd version.
	declare -A SLOT_TO_DMD_VERSIONS
	for version in "${!GCC_TO_KEYWORDS[@]}"; do
		if ! can_handle "${version}"; then continue; fi
		slot="${version%%\.*}"
		dmdVersion="$(get_gcc_dmd_version "${version}")"

		if [[ ! -v SLOT_TO_DMD_VERSIONS[${slot}] ]]; then
			# First time seeing a version for $slot, not much to check.
			SLOT_TO_DMD_VERSIONS[${slot}]="${dmdVersion}"

			# Don't forget that we also have to generate GDC_TARGETS.
			if can_handle "${slot}"; then
				# Same notes as above.
				GDC_TARGETS+=("${slot}\"]=\"${dmdVersion} ${SLOT_TO_KEYWORDS[${slot}]}\"")
			fi
		else
			# We know what dmdVersion should be for a slot.
			if [[ ${SLOT_TO_DMD_VERSIONS[${slot}]} != ${dmdVersion} ]]; then
				eerror "Found multiple dmd versions in the same slot ${slot}."
				eerror "Did gcc's policies change?"
				die "Assumptions by this script about gcc slots were not met"
			else
				# All good :)
				:
			fi
		fi
	done
fi

# Sort the GDC_TARGETS array
IFS=$'\n' GDC_TARGETS=($(sort -n <<<"${GDC_TARGETS[*]}"))
unset IFS

perl -0777 -i -wpe \
	's{
	(_dlang_gdc_frontend=\() # prefix of the lines we want to change, capturing
	(?:.*?) # Everything in-between until a paranthesis, non greedy, non capturing
	(\n\s*\)) # Capture the end paranthesis `\)`, include the newline and the spacing
	}{$1'"$(printf '\n\t\t["%s' "${GDC_TARGETS[@]}")"'$2}xs' \
	eclass/dlang-compilers.eclass
	# x - ignore comments in the regex, and whitespaces
	# s - allow . to match \n
	# replace all the lines in between $1 `_dlang_gdc_frontend(`
	# and $2 `)` with the elements of ${GDC_TARGETS[@]}, separated by \n and \t\t.
	# The first element also gets this delimiter, hence we don't capture the \n
	# in the first group but we do in the last group.
	# We also add back the [" we trimed before

##### Add the USE flag descriptions #####
declare -a GDC_DESCRIPTIONS
for slot in "${!SLOT_TO_KEYWORDS[@]}"; do
	if ! can_handle "${slot}"; then continue; fi
	# slot is a simple number: 11, 12, 13 etc.

	# Same as for the other array, we wil add the prefix 'gdc-' later.
	GDC_DESCRIPTIONS+=("${slot} - Build for GCC ${slot}")
done

# Sort the descriptions
IFS=$'\n' GDC_DESCRIPTIONS=($(sort -n <<<"${GDC_DESCRIPTIONS[*]}"))
unset IFS

perl -0777 -i -wpe \
	 's{
	 (?:^gdc.*\n)+ # we change all the lines that start with gdc
	 # We need the multiline mode (m) below to make ^ match at embeded new lines
	 }{'"$(printf 'gdc-%s\n' "${GDC_DESCRIPTIONS[@]}")"'\n}xm' profiles/use.desc

