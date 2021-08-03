#!/usr/bin/env bash

# set -ex
#   lpass status
# set +ex

dir=$(dirname $0)

fly -t ${CONCOURSE_TARGET:-bosh-ecosystem} \
  sp -p golang-release \
  -c $dir/pipeline.yml \
  -l <(lpass show --notes 'golang-release pipeline vars')
