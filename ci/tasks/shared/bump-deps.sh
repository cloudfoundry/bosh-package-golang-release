#!/bin/bash

set -eux

cp -a input_repo/. output_repo/

cd output_repo/$SOURCE_PATH

if [ ! -z "$GO_PACKAGE" ]; then
  source /var/vcap/packages/$GO_PACKAGE/bosh/compile.env
  # Since we are using Go modules, the GOPATH is not needed and actually conflicts with using modules
  unset GOPATH
fi

#intentionally cause an explicit commit if the underlying go version in our compiled Dockerfile changes.
#assume the go-dep-bumper and bosh-utils are bumping at the same cadence.
GO_MAJOR=$(go version | sed 's/go version go\([0-9]\+\)\.\([0-9]\+\)[. ].*$/\1/g')
GO_MINOR=$(go version | sed 's/go version go\([0-9]\+\)\.\([0-9]\+\)[. ].*$/\2/g')
CURRENT_GO_MOD_MAJOR_MINOR=$(cat go.mod | grep -E "^go 1.*" | sed "s/^\(go \)\([0-9.]\+\)/\2/")

if [ -z "${DESIRED_GO_MAJOR_MINOR}" ]; then
  DESIRED_GO_MAJOR_MINOR="${GO_MAJOR}.$((GO_MINOR-1))"
fi

go get -u ./... go@${DESIRED_GO_MAJOR_MINOR}.0 toolchain@go${DESIRED_GO_MAJOR_MINOR}.0

if [ -d ./tools ]; then
  go get -u ./tools go@${DESIRED_GO_MAJOR_MINOR}.0 toolchain@go${DESIRED_GO_MAJOR_MINOR}.0
fi

go mod tidy -go=${DESIRED_GO_MAJOR_MINOR}.0

go mod vendor

if [ "$(git status --porcelain)" != "" ]; then
  git status
  git add go.mod
  [ -f go.sum ] && git add vendor go.sum
  git config user.name "${GIT_USER_NAME}"
  git config user.email "${GIT_USER_EMAIL}"
  if [ "${CURRENT_GO_MOD_MAJOR_MINOR}" == "${DESIRED_GO_MAJOR_MINOR}" ]; then
    git commit -m "Update vendored dependencies"
  else
    git commit -m "Update go version to ${DESIRED_GO_MAJOR_MINOR}" -m "- (and update vendored dependencies)"
  fi
fi
