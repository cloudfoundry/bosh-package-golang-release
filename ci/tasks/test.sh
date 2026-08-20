#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_dir="${script_dir}/../../.."

# Sourced rather than executed so the docker service can be stopped on exit;
# see https://github.com/cloudfoundry/bosh/blob/main/ci/dockerfiles/docker-cpi/README.md
source start-bosh

set +x
source /tmp/local-bosh/director/bosh-env
set -x

export STEMCELL_PATH="$build_dir/stemcell/stemcell.tgz"
export STEMCELL_VERSION=$(cat stemcell/version)

export OS="ubuntu-noble"
export JOB_NAME="test"
export VM_EXTENSIONS="[]"

${build_dir}/golang-release/tests/run.sh
