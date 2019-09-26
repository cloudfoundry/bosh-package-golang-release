#!/bin/bash -ex

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${script_dir}/..
  while getopts "wl" option; do
    case $option in
      w)
        export STEMCELL_NAME="bosh-google-kvm-windows2019-go_agent"
        export STEMCELL_VERSION="2019.11"
        export STEMCELL_SHA1="9b02446145b49bda4903061611e8af914a979683"
        export OS="windows2019"
        export JOB_NAME="test-windows"
        export VM_EXTENSIONS="[50GB_ephemeral_disk]"
        ;;
      l)
        export STEMCELL_NAME="bosh-warden-boshlite-ubuntu-xenial-go_agent"
        export STEMCELL_VERSION="456.27"
        export STEMCELL_SHA1="518b991efb9d1e5fb2c861e7c180e076ae66f76e"
        export OS="ubuntu-xenial"
        export JOB_NAME="test"
        export VM_EXTENSIONS="[]"
        ;;
    esac
  done

  echo "-----> `date`: Upload stemcell"
  bosh -n upload-stemcell "https://bosh.io/d/stemcells/${STEMCELL_NAME}?v=${STEMCELL_VERSION}" \
    --sha1 $STEMCELL_SHA1 \
    --name $STEMCELL_NAME \
    --version $STEMCELL_VERSION

  echo "-----> `date`: Delete previous deployment"
  bosh -n -d test delete-deployment --force

  echo "-----> `date`: Deploy"
  pushd $PWD
    bosh -n -d test deploy ./manifests/test.yml -v os="${OS}" -v job-name="${JOB_NAME}" -v ephemeral-disk="${VM_EXTENSIONS}"
  popd

  release_version=$(bosh releases --json | jq -r '[.Tables[0].Rows[] | select(.name == "golang")][0].version')

  echo "----> `date`: Export to test compilation"
  pushd $PWD
    bosh -n -d test export-release golang/${release_version//\*} "${OS}/${STEMCELL_VERSION}" --dir ./releases
  popd

  echo "-----> `date`: Run test errand"
  bosh -n -d test run-errand golang-1-${JOB_NAME}
  bosh -n -d test run-errand golang-1.12-${JOB_NAME}
  bosh -n -d test run-errand golang-1.13-${JOB_NAME}

  echo "-----> `date`: Delete deployments"
  bosh -n -d test delete-deployment

  echo "-----> `date`: Done"
popd
