#!/usr/bin/env bash

set -eu

task_dir=$PWD
repo_output=$task_dir/output_repo

git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_EMAIL

git clone input_repo "$repo_output"

cd "$repo_output/$RELEASE_DIR"

for package_to_remove in $(echo "$PACKAGES_TO_REMOVE" | jq -r '.[]'); do
  rm -rf packages/$package_to_remove
done

echo "$PRIVATE_YML" > config/private.yml

for package in $(echo "$PACKAGES" | jq -r '.[]'); do
  bosh vendor-package $package "$task_dir/golang-release"
done

if [ -z "$(git status --porcelain)" ]; then
  exit
fi

git add -A

package_list=$(echo "$PACKAGES" | jq -r 'join(", ")')
first_package=$(echo "$PACKAGES" | jq -r '.[0]')
first_version=$(cat "$task_dir/golang-release/packages/$first_package/version")
git commit -m "Update $package_list packages to $first_version from golang-release

Removed: $(echo "$PACKAGES_TO_REMOVE" | jq -r '. | join(", ")')"
