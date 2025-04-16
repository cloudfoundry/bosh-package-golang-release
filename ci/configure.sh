#!/usr/bin/env bash

dir=$(dirname $0)

fly -t ${CONCOURSE_TARGET:-bosh} \
  sp -p golang-release \
  -c $dir/pipeline.yml
