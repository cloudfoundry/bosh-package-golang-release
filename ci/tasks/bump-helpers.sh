function replace_if_necessary() {
  version=$1
  platform=$2
  blobname=$(basename $(ls ../golang-${version}/*${platform}*))
  if ! bash -c "bosh blobs | grep -q ${blobname}"; then
    existing_blob=$(bosh blobs | awk '{print $1}' | grep "go${version}.*${platform}")
    bosh remove-blob ${existing_blob}
    bosh add-blob --sha2 ../golang-${version}/${blobname} ${blobname}
  fi
}

