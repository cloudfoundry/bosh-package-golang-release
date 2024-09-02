# golang

Note: requires bosh-cli version `v2.0.36`+ to `vendor-package` and `create-release`.

To vendor golang package into your release, run:

```
$ git clone https://github.com/cloudfoundry/bosh-package-golang-release
$ cd ~/workspace/your-release
$ bosh vendor-package golang-1.22-linux ~/workspace/bosh-package-golang-release
```

Included packages:

- `golang-1-{linux,darwin,windows}`: updated with latest version of go 1.x
- `golang-1.22-{linux,darwin,windows}`: updated with latest version of go 1.22.x
- `golang-1.23-{linux,darwin,windows}`: updated with latest version of go 1.23.x

To use `golang-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.22-linux/bosh/compile.env
go build ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.22-windows\bosh\compile.ps1
go build ...
```
[advanced use] To use `golang-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.22-linux/bosh/runtime.env
go run ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.22-windows\bosh\runtime.ps1
go run ...
```

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## Adding a new golang line

To add a new line, edit the variable in the top of `dev/add-line`
Execute the script, commit changes, and update the pipeline.

The blobs necessary for the new version line will automatically be added via CI. The `build-docker-image` job will fail until the blobs are added by the `bump` job.

### Windows

You will need to set the following variables, for example:

```
export STEMCELL_PATH="/path/to/windows/stemcell.zip"
export STEMCELL_VERSION="<version>"
export OS="windows2019"
export JOB_NAME="test-windows"
export VM_EXTENSIONS="[50GB_ephemeral_disk]"
```

## Shared Concourse tasks

This repository provides a couple helpful Concourse tasks in `ci/tasks/shared` that can help keep the Golang package vendored in your BOSH release up to date, and bump dependencies.

### ci/tasks/shared/bump-golang-package

The `bump-golang-package` task runs `bosh vendor-package` to automatically update the version of Golang vendored into your own BOSH release.

* `GIT_USER_NAME`: Required. The email that will be used to generate commits.
* `GIT_USER_EMAIL`: Required. The user name that will be used to generate commits.
* `PACKAGES`: Required. Specifies Golang packages will be vendored into your own BOSH release, e.g. the `golang-1-linux` package.
* `PACKAGES_TO_REMOVE`: Optional. A list of packages to remove from the release. This can be useful if one is bumping from `golang-1.x-linux` to `golang-1.y-linux` and `1.y` is intended to replace `1.x`/
* `PRIVATE_YML`: Required. The contents of config/private.yml for your own BOSH release. Necessary to run `bosh vendor-package`.
* `RELEASE_DIR`: Required. The directory where your release has been cloned on disk.

### ci/tasks/shared/bump-deps

The `bump-deps` task will update to go version specified in `go.mod` and then run `go get -u ./...`, and if a `tools` package is present `go get -u ./tools` in the `$SOURCE_PATH` directory specified.

* `GIT_USER_NAME`: Required. The email that will be used to generate commits.
* `GIT_USER_EMAIL`: Required. The user name that will be used to generate commits.
* `GO_PACKAGE`: Required. The location of the vendored Golang package to be used when running `go` commands.
* `SOURCE_PATH`: Required. The location of the Golang source you wish to update. Must contain a `go.mod` file. 
