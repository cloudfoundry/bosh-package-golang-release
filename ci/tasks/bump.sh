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
  git commit -am "Bump to golang $(cat ../golang-1.16/.resource/version)" -m "$(cd ../golang-1.16 && ls)"
fi

replace_if_necessary 1.17 linux true
replace_if_necessary 1.17 darwin true
replace_if_necessary 1.17 windows true

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump to golang $(cat ../golang-1.17/.resource/version)" -m "$(cd ../golang-1.17 && ls)"
fi
