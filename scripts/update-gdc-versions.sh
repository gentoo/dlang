#!/bin/bash
# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# This script uses various utilities from app-portage/portage-utils

# No -u because /lib/gentoo/functions.sh doesn't work with it
set -eo pipefail
shopt -s nullglob

source /lib/gentoo/functions.sh

REPO="$(dirname "${0}")"
cd "${REPO}/.."
readonly EROOT=$(portageq envvar EROOT)
readonly PORTDIR=$(portageq get_repo_path "${EROOT}" gentoo)

# Associative array betwen gcc $PVRs and their keywords
declare -A GCC_TO_KEYWORDS
# Associative array between gcc slots (gdmd versions) and a combination
# of the keywords of each gcc version is said slot.
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
	[[ $# -ne 1 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}"

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
	[[ $# -ne 2 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}"
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
	[[ $# -ne 2 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}"
	local v1=($1) v2=($2) # We want the expansion

	# We take advantage that the keyword arrays are sorted
	local n=${#v1[@]} m=${#v2[@]}
	local i=0 j=0

	local result=()

	while (( i < n && j < m )); do
		local a1=$(keyword_to_arch "${v1[$i]}")
		local a2=$(keyword_to_arch "${v2[$j]}")

		if [[ $a1 = $a2 ]]; then
			result+=("$(combine_arch_keywords "${v1[$i]}" "${v2[$j]}")")
			((++i, ++j)) || true
		elif [[ $a1 < $a2 ]]; then
			result+=("${v1[$i]}")
			((++i)) || true
		else
			result+=("${v2[$j]}")
			((++j)) || true
		fi
	done

	result+=("${v1[@]:$i}")
	result+=("${v2[@]:$j}")

	echo "${result[@]}"
}

# Check if there is an ebuild of gdmd for a specific version of gcc.
# $1 can either be a gcc slot of a gcc version, they are both calculated
# in the same way.
can_handle () {
	[[ $# -ne 1 ]] && die "Internal error: Passed $# arguments to ${FUNCNAME}"

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

###### Modify keywords for each gdmd ebuild #######
for slot in "${!SLOT_TO_KEYWORDS[@]}"; do
	if ! can_handle "${slot}"; then continue; fi

	file="dev-util/gdmd/gdmd-${slot}.ebuild"
	sed -i -e 's/^KEYWORDS=.*$/KEYWORDS="'"${SLOT_TO_KEYWORDS[$slot]}"'"/' "${file}"
done

##### Calculate gdc frontends #####
declare -a GDC_TARGETS
for version in "${!GCC_TO_KEYWORDS[@]}"; do
	if ! can_handle "${version}"; then continue; fi
	# For a gdc USE flag, we need only the package version (i.e. no -r* sufix)
	pv="${version%-r*}"

	ebuild="${PORTDIR}/sys-devel/gcc/gcc-${version}.ebuild"
	asroot ebuild "${ebuild}" unpack

	prefix="$(portageq envvar PORTAGE_TMPDIR)/portage/sys-devel/gcc-${version}"

	# Make /var/tmp/portage/sys-devel/gcc* traversable for the normal user
	# to prevent asking for the root password for each file we want to check.
	asroot chmod +rx "${prefix}" "${prefix}/work"

	# I don't know how to expand the string properly, without bash quiting due to the error of not finding the path
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

	# For the format of an element look in eclass/dlang-compilers.eclass.

	# Don't add the [" that should be at the beggining of an element
	# because we will need to sort the array and `sort -n` doesn't like
	# the leading non-numerical characters.
	# We will add [" later.
	GDC_TARGETS+=("${pv}\"]=\"${dmdVersion} ${GCC_TO_KEYWORDS[$version]}\"")

	asroot ebuild "${ebuild}" clean
done

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
for version in "${!GCC_TO_KEYWORDS[@]}"; do
	if ! can_handle "${version}"; then continue; fi
	# $version may look like: 11.3.1_p20221209, 11.4.0, 10.3.1_p20230426-r1
	# we need use.desc to contain:
	# gdc-11_3_1_p20231209 - Build for GCC 11.3.1_p20221209
	# gdc-11_4_0 - Build for GCC 11.4.0
	# gdc-10_3_1_p20230426 - Build for GCC 10.3.1_p20230426

	pv="${version%-r*}"

	# For each line add the text starting from the version (remove 'gdc-')
	# to be able to sort the entries properly after.
	gdc="${pv//./_}"
	gcc="${pv}"
	GDC_DESCRIPTIONS+=("${gdc} - Build for GCC ${gcc}")
done

# Sort the descriptions
IFS=$'\n' GDC_DESCRIPTIONS=($(sort -n <<<"${GDC_DESCRIPTIONS[*]}"))
unset IFS

perl -0777 -i -wpe \
	 's{
	 (?:^gdc.*\n)+ # we change all the lines that starts with gdc
	 # We need the multiline mode (m) below to make ^ match and embeded new lines
	 }{'"$(printf 'gdc-%s\n' "${GDC_DESCRIPTIONS[@]}")"'\n}xm' profiles/use.desc

exit 0
