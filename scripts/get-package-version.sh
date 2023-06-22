#!/usr/bin/env bash

dir="$(dirname $0)"

fingerprint="${1}"
package="${2}"

if [ -z "${fingerprint}" ] || [ -z "${package}" ]; then
    echo "Usage: ${0} <fingerprint> <package-name>"
    exit 1;
fi

cd "${dir}"
git log -S  "${fingerprint}" --format=format:%H | head -1 | xargs -I {} git show {}:"packages/${package}/version"
