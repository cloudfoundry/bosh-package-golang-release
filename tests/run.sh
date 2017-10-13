#!/bin/bash

set -e # -x

echo "-----> `date`: Upload stemcell"
bosh -n upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=3445.2" \
  --sha1 7ff35e03ab697998ded7a1698fe6197c1a5b2258 \
  --name bosh-warden-boshlite-ubuntu-trusty-go_agent \
  --version 3445.2

echo "-----> `date`: Delete previous deployment"
bosh -n -d test delete-deployment --force

echo "-----> `date`: Deploy"
( set -e; cd ./..; bosh -n -d test deploy ./manifests/test.yml -v os=ubuntu-trusty -v job-name=test )

echo "-----> `date`: Run test errand"
bosh -n -d test run-errand golang-1.8-test
bosh -n -d test run-errand golang-1.9-test

echo "-----> `date`: Delete deployments"
bosh -n -d test delete-deployment

echo "-----> `date`: Done"
