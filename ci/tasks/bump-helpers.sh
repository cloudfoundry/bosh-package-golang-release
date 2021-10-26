function replace_if_necessary() {
  version=$1
  platform=$2
  is_latest=${3:-0}
  blobname=$(basename $(ls ../golang-${version}/*${platform}*))

  cp ../golang-${version}/.resource/version ./packages/golang-${version}-${platform}/
  if [ $is_latest ]; then
    cp ../golang-${version}/.resource/version ./packages/golang-1-${platform}/
  fi

  if ! bosh blobs | grep -q ${blobname}; then
    existing_blob=$(bosh blobs | awk '{print $1}' | grep "go${version}.*${platform}" || true)
    if [ -n "${existing_blob}" ]; then
      bosh remove-blob ${existing_blob}
    fi
    bosh add-blob --sha2 ../golang-${version}/${blobname} ${blobname}
    bosh upload-blobs
  fi
}