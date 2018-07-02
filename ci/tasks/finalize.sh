#!/usr/bin/env bash

set -eux

# invariants
cp semver/version bumped-semver/version
cp -rfp ./golang-release/. finalized-release

# finalize
export FULL_VERSION=$(cat semver/version)

pushd finalized-version
  git status

  set +x
  echo "${PRIVATE_YML}" > config/private.yml
  set -x

  bosh upload-blobs
  bosh finalize-release --version $FULL_VERSION

  git add -A
  git status

  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"

  git commit -m "Adding final release $FULL_VERSION via concourse"
popd

echo "v${FULL_VERSION}" > version-tag/tag-name
echo "Final release ${FULL_VERSION} tagged via concourse" > version-tag/annotate-msg
