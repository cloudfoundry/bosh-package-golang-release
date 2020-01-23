#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_dir="${script_dir}/../../.."

start-bosh

source /tmp/local-bosh/director/env

curl -Lo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x /usr/local/bin/jq

export STEMCELL_PATH="stemcell/stemcell.tgz"
export STEMCELL_VERSION=$(cat stemcell/version)

export OS="ubuntu-xenial"
export JOB_NAME="test"
export VM_EXTENSIONS="[]"

${build_dir}/golang-release/tests/run.sh
