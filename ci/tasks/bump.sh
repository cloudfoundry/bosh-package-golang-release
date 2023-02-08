#!/usr/bin/env bash

set -eux

function replace_if_necessary() {
  version=$1
  platform=$2
  blobname=$(basename $(ls ../golang-${version}/*${platform}*))

  cp ../golang-${version}/.resource/version ./packages/golang-${version}-${platform}/

  if ! bosh blobs | grep -q ${blobname}; then
    existing_blob=$(bosh blobs | awk '{print $1}' | grep "go${version}.*${platform}" || true)
    if [ -n "${existing_blob}" ]; then
      bosh remove-blob ${existing_blob}
    fi
    bosh add-blob --sha2 ../golang-${version}/${blobname} ${blobname}
    bosh upload-blobs
  fi
}

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
# Thus we need to determine which version is the latest version, in order to properly
# set the version for the golang-1-{PLATFORM} packages.
declared_versions=("1.20" "1.19")
IFS=$'\n' versions=($(sort <<< "${declared_versions[*]}"))
unset IFS

latest_version="${versions[-1]}"

platforms=(linux darwin windows)

for version in ${versions[*]}; do
  for platform in ${platforms[*]}; do
    replace_if_necessary $version $platform

    if [[ "$version" == "$latest_version" ]]; then
      cp "../golang-${version}/.resource/version" "./packages/golang-1-${platform}/"
    fi
  done

  if [[ "$( git status --porcelain )" != "" ]]; then
    git commit -am "Bump to golang $(cat ../golang-$version/.resource/version)" -m "$(cd ../golang-$version && ls)"
  fi
done
