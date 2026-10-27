#!/bin/bash

set -eux

cp -a input_repo/. output_repo/

cd "output_repo/${SOURCE_PATH}"

if [ -n "${GO_PACKAGE}" ]; then
  # shellcheck disable=SC1090
  source "/var/vcap/packages/${GO_PACKAGE}/bosh/compile.env"
  # Since we are using Go modules, the GOPATH is not needed and actually conflicts with using modules
  unset GOPATH
fi

GO_MAJOR=$(go version | sed -E 's/go version go([0-9]+)\.([0-9]+)[. ].*$/\1/')
GO_MINOR=$(go version | sed -E 's/go version go([0-9]+)\.([0-9]+)[. ].*$/\2/')
CURRENT_GO_MOD_MAJOR_MINOR=$(sed -nE 's/^go ([0-9]+\.[0-9]+).*/\1/p' go.mod)

if [ -z "${DESIRED_GO_MAJOR_MINOR}" ]; then
  DESIRED_GO_MAJOR_MINOR="${GO_MAJOR}.$((GO_MINOR-1))"
fi

function go_get() {
  local go_version="${DESIRED_GO_MAJOR_MINOR}"
  local package_arg="${1}"
  local args=(-u)
  if [[ -n "${BUMP_TEST_DEPS:-}" ]]; then
    args+=(-t)
  fi

  GOOS="${goos}" go get "${args[@]}" \
    "${package_arg}" \
    "go@${go_version}" \
    "toolchain@go${go_version}"
}

# shellcheck disable=SC2206
goos_array=(${GOOS_LIST//,/ })

if (( ${#goos_array[@]} == 0 )); then
  echo "Error: GOOS_LIST was empty, at least one valid GOOS value must be provided"
  exit 1
fi

# Loop through the GOOS array
for goos in "${goos_array[@]}"; do
  go_get ./...

  # Update Go 1.24+ tool dependencies if any are declared.
  if grep -qE '^tool |^tool\s*\(' go.mod; then
    echo "Updating go.mod tool entries and dependencies..."
    go_get tool
  fi

  if [ -d ./tools ]; then
    echo "Updating legacy 'tools.go pattern' dependencies..."
    go_get ./tools
  fi
done

# Only upgrade the full module graph (including test dependencies of dependencies) when
# a direct bump is already happening, so indirect-only updates don't produce extra commits.
if ! git diff --quiet -- go.mod; then
  # certstrap v1.4.1 requires Go 1.27.3; exclude it for Go 1.26 bumps until https://github.com/cloudfoundry/bosh-package-golang-release/issues/51.
  go mod edit -exclude=github.com/square/certstrap@v1.4.1
  for goos in "${goos_array[@]}"; do
    GOOS="${goos}" go get -u -t all "go@${DESIRED_GO_MAJOR_MINOR}" "toolchain@go${DESIRED_GO_MAJOR_MINOR}"
  done
  go mod edit -dropexclude=github.com/square/certstrap@v1.4.1
fi

go mod tidy

UPDATED_GO_MOD_MAJOR_MINOR=$(sed -nE 's/^go ([0-9]+\.[0-9]+).*/\1/p' go.mod)
if [ "${UPDATED_GO_MOD_MAJOR_MINOR}" != "${DESIRED_GO_MAJOR_MINOR}" ]; then
  echo "Error: go.mod requires Go ${UPDATED_GO_MOD_MAJOR_MINOR}, expected ${DESIRED_GO_MAJOR_MINOR}.x" >&2
  exit 1
fi

go mod vendor

if [ -n "$(git status --porcelain -- go.mod go.sum vendor)" ]; then
  git status
  git add go.mod
  [ -f go.sum ] && git add vendor go.sum
  git config user.name "${GIT_USER_NAME}"
  git config user.email "${GIT_USER_EMAIL}"
  if [ "${CURRENT_GO_MOD_MAJOR_MINOR}" == "${DESIRED_GO_MAJOR_MINOR}" ]; then
    commit_message="Update vendored dependencies"
  else
    commit_message="Update go version to ${DESIRED_GO_MAJOR_MINOR}

- (and update vendored dependencies)"
  fi
  if [ -n "${GIT_COMMIT_MESSAGE_SUFFIX:-}" ]; then
    commit_message="${commit_message}${GIT_COMMIT_MESSAGE_SUFFIX}"
  fi
  git commit -m "${commit_message}"
fi
