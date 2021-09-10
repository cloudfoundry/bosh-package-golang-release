#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${script_dir}/bump-helpers.sh

cd bumped-golang-release

git clone ../golang-release .

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

git config user.name "CI Bot"
git config user.email "cf-bosh-eng@pivotal.io"

replace_if_necessary 1.16 linux
replace_if_necessary 1.16 darwin
replace_if_necessary 1.16 windows

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump golang 1.16" -m "$(cd ../golang-1.16 && ls)"
fi

replace_if_necessary 1.17 linux
replace_if_necessary 1.17 darwin
replace_if_necessary 1.17 windows

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump golang 1.17" -m "$(cd ../golang-1.17 && ls)"
fi
