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

# The dev/add-line script blindly replaces the old version being removed with the
# new version being added. This means that the two versions may swap orders within
# this script.
#
# Thus we need to determine whether the "first" or "second" version is the latest
# version, which we need to know in order to properly set the version for the
# golang-1-{PLATFORM} package.
first_version="1.18"
second_version="1.17"
if [[ "$first_version" < "$second_version" ]]; then
  first_version_is_latest=false
  second_version_is_latest=true
else
  first_version_is_latest=true
  second_version_is_latest=false
fi

replace_if_necessary $first_version linux $first_version_is_latest
replace_if_necessary $first_version darwin $first_version_is_latest
replace_if_necessary $first_version windows $first_version_is_latest

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump to golang $(cat ../golang-$first_version/.resource/version)" -m "$(cd ../golang-$first_version && ls)"
fi

replace_if_necessary $second_version linux $second_version_is_latest
replace_if_necessary $second_version darwin $second_version_is_latest
replace_if_necessary $second_version windows $second_version_is_latest

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump to golang $(cat ../golang-$second_version/.resource/version)" -m "$(cd ../golang-$second_version && ls)"
fi
