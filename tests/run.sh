#!/bin/bash -ex

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${script_dir}/..
  while getopts "wl" option; do
    case $option in
      w)
        export STEMCELL_NAME="bosh-google-kvm-windows2012R2-go_agent"
        export STEMCELL_VERSION="1200.4"
        export STEMCELL_SHA1="ef6aefa5a27fa7e378637a5875911ec3b1e44927"
        export OS="windows2012R2"
        export JOB_NAME="test-windows"
        export VM_EXTENSIONS="[50GB_ephemeral_disk]"
        ;;
      l)
        export STEMCELL_NAME="bosh-warden-boshlite-ubuntu-trusty-go_agent"
        export STEMCELL_VERSION="3541.10"
        export STEMCELL_SHA1="11c07b63953710d68b7f068e0ecb9cb8f7e64f6a"
        export OS="ubuntu-trusty"
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

  release_version=$(bosh releases --json | jq -r .Tables[0].Rows[0].version)

  echo "----> `date`: Export to test Windows compilation"
  pushd $PWD
    bosh -n -d test export-release golang/${release_version//\*} "${OS}/${STEMCELL_VERSION}" --dir ./releases
  popd

  echo "-----> `date`: Run test errand"
  bosh -n -d test run-errand golang-1-${JOB_NAME}
  bosh -n -d test run-errand golang-1.12-${JOB_NAME}
  bosh -n -d test run-errand golang-1.11-${JOB_NAME}

  echo "-----> `date`: Delete deployments"
  bosh -n -d test delete-deployment

  echo "-----> `date`: Done"
popd
