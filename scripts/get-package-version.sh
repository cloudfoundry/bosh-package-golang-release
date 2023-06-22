#!/usr/bin/env bash

dir="$(dirname $0)"

cd "${dir}"
git log -S  "${1}" --format=format:%H | head -1 | xargs -I {} git show {}:"packages/${2}/version"
