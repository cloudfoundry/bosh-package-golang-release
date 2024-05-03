#!/usr/bin/env bash

set -euo pipefail

updated_package=0
previous_binary="$(ls previous_binary/${PREVIOUS_BINARY_PATTERN})"
current_binary="$(ls current_binary/${CURRENT_BINARY_PATTERN})"

previous_version="$(go version "${previous_binary}" | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' | tail -n 1)"
current_version="$(go version "${current_binary}" | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' | tail -n 1)"

echo "Previous go version: ${previous_version}"
echo "Current go version: ${current_version}"

if [ "${current_version}" != "${previous_version}" ]; then
  updated_package=1
  release_notes="### Updates:"
  release_notes="${release_notes}
* Update to golang ${current_version}"
fi

if [ "${updated_package}" == "0" ]; then
  echo "Golang Version Not Updated"
  exit 1
fi

echo "$release_notes"

echo "$release_notes" >> release-notes/release-notes.md
touch release-notes/needs-release
