#!/bin/bash

# Update these variables when adding a new line
old=1.25
last=1.26
new=1.27

# packages
for dir in darwin darwin-test linux linux-test windows windows-test; do
    cp -fr packages/golang-{${last},${new}}-${dir}/
    rm -fr packages/golang-${old}-${dir}/
done

find packages/*-${new}-* -type file -print0 | xargs -0 sed -i "" "s/${last}/${new}/g"
find packages/*-1-* -type file -print0 | xargs -0 sed -i "" "s/${last}/${new}/g"

# reset placeholder patch versions to major.minor.0 until the pipeline bumps them
for version_file in packages/golang-${new}-{darwin,linux,windows}/version packages/golang-1-{darwin,linux,windows}/version; do
    printf "%s.0" "${new}" > "${version_file}"
done

# jobs
for dir in test test-windows; do
    cp -fr jobs/golang-{${last},${new}}-${dir}/
    rm -fr jobs/golang-${old}-${dir}/
done

find jobs/*-${new}-* -type file -print0 | xargs -0 sed -i "" "s/${last}/${new}/g"
find jobs/*-1-* -type file -print0 | xargs -0 sed -i "" "s/${last}/${new}/g"

# blobs
for blob in $(bosh blobs | awk '{print $1}' | grep go${old}); do
    bosh remove-blob ${blob}
done

# ci
find ci -type file -print0 | xargs -0 sed -i "" "s/${old}/${new}/g"

# test
find tests manifests -type file -print0 | xargs -0 sed -i "" "s/${old}/${new}/g"

# README
if grep ${old} README.md; then
    sed -i "" "s/${last}/${new}/g" README.md
    sed -i "" "s/${old}/${last}/g" README.md
fi

echo "added ${new}, removed ${old}"
echo "please commit changes and push"
echo "when pushed run ./ci/configure.sh to update pipeline"
echo "the pipeline will add the required blobs"
