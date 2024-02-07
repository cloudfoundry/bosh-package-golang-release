#!/bin/bash -ex

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd ${script_dir}/..
  echo "-----> `date`: Upload stemcell"
  bosh -n upload-stemcell "${STEMCELL_PATH}"

  echo "-----> `date`: Delete previous deployment"
  bosh -n -d test delete-deployment --force

  echo "-----> `date`: Deploy"
  bosh -n -d test deploy ./manifests/test.yml -v os="${OS}" -v job-name="${JOB_NAME}" -v ephemeral-disk="${VM_EXTENSIONS}"

  release_version=$(bosh releases --json | jq -r '[.Tables[0].Rows[] | select(.name == "golang")][0].version')

  echo "----> `date`: Export to test compilation"
  bosh -n -d test export-release golang/${release_version//\*} "${OS}/${STEMCELL_VERSION}" --dir ./releases

  echo "-----> `date`: Run test errand"
  bosh -n -d test run-errand golang-1-${JOB_NAME}
  bosh -n -d test run-errand golang-1.21-${JOB_NAME}
  bosh -n -d test run-errand golang-1.22-${JOB_NAME}

  echo "-----> `date`: Delete deployments"
  bosh -n -d test delete-deployment

  echo "-----> `date`: Done"
popd
