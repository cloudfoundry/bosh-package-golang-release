#!/usr/bin/env bash

set -eux

function replace_if_necessary() {
  version=$1
  platform=$2
  arch=$3
  # Match on "<platform>-<arch>" so the per-architecture linux tarballs
  # (linux-amd64, linux-arm64) are tracked as separate blobs.
  blobname=$(basename $(ls ../golang-${version}/*.${platform}-${arch}.*))

  cp ../golang-${version}/.resource/version ./packages/golang-${version}-${platform}/

  if ! bosh blobs | grep -q ${blobname}; then
    existing_blob=$(bosh blobs | awk '{print $1}' | grep "go${version}.*\.${platform}-${arch}\." || true)
    if [ -n "${existing_blob}" ]; then
      bosh remove-blob ${existing_blob}
    fi
    bosh add-blob --sha2 ../golang-${version}/${blobname} ${blobname}
    bosh upload-blobs
  fi
}

# linux also ships arm64 so the golang linux packages compile on arm64 VMs.
function platform_arches() {
  case "$1" in
    linux) echo "amd64 arm64" ;;
    *)     echo "amd64" ;;
  esac
}

cd bumped-golang-release

git clone ../golang-release .

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

git config user.name "CI Bot"
git config user.email "cf-bosh-eng@pivotal.io"

# The ci/tasks/add-line.sh script blindly replaces the old version being removed with the
# new version being added. This means that the two versions may swap orders within
# this script.
#
# Thus we need to determine which version is the latest version, in order to properly
# set the version for the golang-1-{PLATFORM} packages.
declared_versions=("1.26" "1.27")
IFS=$'\n' versions=($(sort <<< "${declared_versions[*]}"))
unset IFS

latest_version="${versions[-1]}"

platforms=(linux darwin windows)

for version in ${versions[*]}; do
  for platform in ${platforms[*]}; do
    for arch in $(platform_arches $platform); do
      replace_if_necessary $version $platform $arch
    done

    if [[ "$version" == "$latest_version" ]]; then
      cp "../golang-${version}/.resource/version" "./packages/golang-1-${platform}/"
    fi
  done

  if [[ "$( git status --porcelain )" != "" ]]; then
    git commit -am "Bump to golang $(cat ../golang-$version/.resource/version)" -m "$(cd ../golang-$version && ls)"
  fi
done
