#!/usr/bin/env bash

# set -ex
#   lpass status
# set +ex

dir=$(dirname $0)

fly -t ${CONCOURSE_TARGET:-production} \
  sp -p golang-release \
  -c $dir/pipeline.yml \
  -l <(lpass show --notes 'golang-release pipeline vars')
