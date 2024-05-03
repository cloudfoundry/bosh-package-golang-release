#!/usr/bin/env bash

set -euo pipefail

version_number="$(cat version/version)"

updated_package=0
pushd "input_repo"
  for package in $(echo "$PACKAGES" | jq -r '.[]'); do
    current_version="$(git log -n 1 --format=format:"%B" -- packages/${package} | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')"
    previous_version="$(git log -n 1 --format=format:"%B" "v${version_number}" -- packages/${package} | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')"

    if [ "${current_version}" != "${previous_version}" ]; then
      if [ "${updated_package}" == "0" ]; then
        release_notes="### Updates:"
      fi
      updated_package=1

      release_notes="${release_notes}
* Updates golang package ${package} to ${current_version}"
    fi
  done
popd

if [ "${updated_package}" == "0" ]; then
  echo "Golang Version Not Updated"
  exit 1
fi

echo "$release_notes"

echo "$release_notes" >> release-notes/release-notes.md
touch release-notes/needs-release
