#!/usr/bin/env bash

scriptdir=$( cd -- "$(dirname "${0}")" ; pwd -P )
repo=$(dirname "${scriptdir}")

profiles=$(awk 'NF { printf $2 "," } END { print ""}' "${repo}/profiles/profiles.desc")

exec pkgcheck scan -p "${profiles}" "${@}"
