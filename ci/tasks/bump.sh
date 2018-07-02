#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${script_dir}/bump-helpers.sh

echo "${PRIVATE_YML}" > config/private.yml

cd bumped-golang-release
git clone ../golang-release .

replace_if_necessary 1.10 linux
replace_if_necessary 1.10 darwin
replace_if_necessary 1.10 windows

replace_if_necessary 1.9 linux
replace_if_necessary 1.9 darwin
replace_if_necessary 1.9 windows

bosh upload-blobs
