#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_dir="${script_dir}/../../.."

source start-bosh

source /tmp/local-bosh/director/env

export STEMCELL_PATH="$build_dir/stemcell/stemcell.tgz"
export STEMCELL_VERSION=$(cat stemcell/version)

export OS="ubuntu-jammy"
export JOB_NAME="test"
export VM_EXTENSIONS="[]"

${build_dir}/golang-release/tests/run.sh
